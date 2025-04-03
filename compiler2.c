#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LEN 256
#define MAX_LABELS   256
#define MAX_PROG_LEN 1024

// ---------------------------------------------------------------------
// Structuri pentru reținerea instrucțiunilor și a etichetelor
// ---------------------------------------------------------------------

typedef struct {
    char  label[64];   // Numele etichetei (dacă există) - Faza 1
    char  mnemonic[16];
    char  op1[64];     // Primul parametru (dacă există)
    char  op2[64];     // Al doilea parametru (dacă există)
    int   lineNumber;  // Linia în care apare instrucțiunea (numerotăm 0,1,2,...)
    int   hasLabel;
} Instruction;

typedef struct {
    char labelName[64];
    int  instrIndex;   // La ce index de instrucțiune pointează eticheta
} Label;

// ---------------------------------------------------------------------
// Funcție pentru maparea mnemonic -> opcode (5 biți)
// ---------------------------------------------------------------------
int getOpcode(const char *mnemonic)
{
    // Conform listei:
    //  0 – HLT
    //  1 – BRZ
    //  2 – BNR
    //  3 – BRC
    //  4 – BRO
    //  5 – BRA
    //  6 – JMP
    //  7 – RET
    //  8 – ADD
    //  9 – SUB
    // 10 – LSR
    // 11 – LSL
    // 12 – RSR
    // 13 – RSL
    // 14 – MOV
    // 15 – MUL
    // 16 – DIV
    // 17 – MOD
    // 18 – AND
    // 19 – OR
    // 20 – XOR
    // 21 – NOT
    // 22 – CMP
    // 23 – TST
    // 24 – INC
    // 25 – DEC
    // 26 – LDA
    // 27 – STA
    // 28 – LDR
    // 29 – STR
    // 30 – PSH
    // 31 – POP
    if      (strcasecmp(mnemonic, "HLT")==0) return 0;
    else if (strcasecmp(mnemonic, "BRZ")==0) return 1;
    else if (strcasecmp(mnemonic, "BNR")==0) return 2;
    else if (strcasecmp(mnemonic, "BRC")==0) return 3;
    else if (strcasecmp(mnemonic, "BRO")==0) return 4;
    else if (strcasecmp(mnemonic, "BRA")==0) return 5;
    else if (strcasecmp(mnemonic, "JMP")==0) return 6;
    else if (strcasecmp(mnemonic, "RET")==0) return 7;
    else if (strcasecmp(mnemonic, "ADD")==0) return 8;
    else if (strcasecmp(mnemonic, "SUB")==0) return 9;
    else if (strcasecmp(mnemonic, "LSR")==0) return 10;
    else if (strcasecmp(mnemonic, "LSL")==0) return 11;
    else if (strcasecmp(mnemonic, "RSR")==0) return 12;
    else if (strcasecmp(mnemonic, "RSL")==0) return 13;
    else if (strcasecmp(mnemonic, "MOV")==0) return 14;
    else if (strcasecmp(mnemonic, "MUL")==0) return 15;
    else if (strcasecmp(mnemonic, "DIV")==0) return 16;
    else if (strcasecmp(mnemonic, "MOD")==0) return 17;
    else if (strcasecmp(mnemonic, "AND")==0) return 18;
    else if (strcasecmp(mnemonic, "OR")==0)  return 19;
    else if (strcasecmp(mnemonic, "XOR")==0) return 20;
    else if (strcasecmp(mnemonic, "NOT")==0) return 21;
    else if (strcasecmp(mnemonic, "CMP")==0) return 22;
    else if (strcasecmp(mnemonic, "TST")==0) return 23;
    else if (strcasecmp(mnemonic, "INC")==0) return 24;
    else if (strcasecmp(mnemonic, "DEC")==0) return 25;
    else if (strcasecmp(mnemonic, "LDA")==0) return 26;
    else if (strcasecmp(mnemonic, "STA")==0) return 27;
    else if (strcasecmp(mnemonic, "LDR")==0) return 28;
    else if (strcasecmp(mnemonic, "STR")==0) return 29;
    else if (strcasecmp(mnemonic, "PSH")==0) return 30;
    else if (strcasecmp(mnemonic, "POP")==0) return 31;

    // Necunoscut
    return -1;
}

// ---------------------------------------------------------------------
// Funcție ajutătoare: verifică dacă un șir reprezintă un registru X, Y sau A
// returnează: 0 = nu e registru, 1 = X, 2 = Y, 3 = A
// ---------------------------------------------------------------------
int whichRegister(const char *op)
{
    if (strcasecmp(op, "X") == 0) return 1;
    if (strcasecmp(op, "Y") == 0) return 2;
    if (strcasecmp(op, "A") == 0) return 3;
    return 0;
}

// ---------------------------------------------------------------------
// Funcție care întoarce 1 dacă este branch/jump (BRA, BRZ, BNR etc.) 
// conform specificației: 1..6, deci instructiuni 1-6.
// ---------------------------------------------------------------------
int isBranchOrJump(int opcode)
{
    // 1 – BRZ
    // 2 – BNR
    // 3 – BRC
    // 4 – BRO
    // 5 – BRA
    // 6 – JMP
    // Toate aceste instrucțiuni intră în categorie.
    return (opcode >= 1 && opcode <= 6);
}

// ---------------------------------------------------------------------
// Conversie integer (posibil negativ) la 10 biți (2's complement).
// Se întoarce valoarea (în 0..1023) care reprezintă acei 10 biți.
// ---------------------------------------------------------------------
unsigned int to10BitSigned(int val)
{
    // Dorim să-l mapăm într-un interval de -512..511.
    // Aplicație: val & 0x3FF, dar cu grijă la semn.
    // O variantă simplă: forțăm val în [-512, 511] și apoi facem "masca" pe 10 biți.
    int temp = val & 0x3FF; // mascare directă (2's complement pe 10 biți)
    return (unsigned int)temp;
}

// ---------------------------------------------------------------------
// Funcție care generează codul mașină pentru (mnemonic, op1, op2)
// Avem nevoie de:
//   - opcode (bits [14:10])
//   - bit15 -> registru (0) sau immediate (1), cu excepții (vezi enunț)
//   - bit9 -> selector registru X=0, Y=1 (dacă e cazul) sau parte din immediate
//   - [8:0] -> valoarea imediată
// ---------------------------------------------------------------------
unsigned short assembleInstruction(int opcode, const char *op1, const char *op2, int currentLine, int isSecondPass,
                                   Label *labels, int labelCount, Instruction *program, int totalInstr)
{
    // Începem cu 0 pe 16 biți
    unsigned short instr = 0;

    // Scriem opcode pe bits [14:10]
    // opcode e pe 5 biți
    unsigned short opc = (unsigned short)(opcode & 0x1F);
    instr |= (opc << 10);

    // By default, bitul 15 = 0 => parametru considerat registru
    // Dar pentru LDR, STR, INC, DEC și toate branch/jump -> bit 15 = 1
    // De asemenea, dacă acest mnemonic suportă parametru immediate #, punem 1.
    // + excepția PSH/POP cu registrul A.
    unsigned short bit15 = 0;

    // Verificăm dacă LDR, STR, INC, DEC, branch/jump => bit15 = 1
    if (opcode == 28 || opcode == 29 ||  // LDR, STR
        opcode == 24 || opcode == 25 ||  // INC, DEC
        isBranchOrJump(opcode))
    {
        bit15 = 1;
    }

    // Avem cazuri diferite în funcție de câți parametri așteaptă mnemonic-ul.
    // Observații generale din enunț:
    //   - 0 param (HLT, RET, NOT, INC, DEC)
    //   - 1 param (majoritatea: ADD #, SUB #, ADD X etc.)
    //   - 2 param (LDR, STR)
    //   - (PSH, POP) – 1 param, dar special: dacă param = A -> bit15=1, altfel=0

    // -------------------------------------------------
    // 0 parametri (ex: HLT, RET, NOT, INC, DEC)
    // -------------------------------------------------
    if (strcasecmp(op1, "") == 0 && strcasecmp(op2, "") == 0) {
        // Example: HLT => totul 0, doar opcode în [14:10].
        //          NOT => bit15 = 0 (?), doar opcode
        //          INC => enunțul spune: bit15 = 1, immediate = 1
        //          DEC => la fel
        if (opcode == 24) { // INC
            // punem bit15=1 și immediate = 1 (pe [9:0])
            bit15 = 1;
            instr |= 1; // [0] = 1
        } else if (opcode == 25) { // DEC
            bit15 = 1;
            instr |= 1; 
        }
    }
    // -------------------------------------------------
    // 2 parametri (doar LDR, STR)
    // LDR X, #12
    // STR Y, #(-5)
    // => bit15=1, bit9=0 sau 1 pt X/Y, [8:0] = immediate
    // -------------------------------------------------
    else if (opcode == 28 || opcode == 29) { // LDR, STR
        // op1 trebuie să fie X sau Y (conform enunțului)
        int reg = whichRegister(op1);
        if (reg == 1) {
            // X => bit9 = 0
            // nimic de pus la instr exact, bit9 rămâne 0
        }
        else if (reg == 2) {
            // Y => bit9 = 1
            instr |= (1 << 9);
        }
        else {
            fprintf(stderr, "Eroare: LDR/STR cu registru invalid '%s'!\n", op1);
        }

        // op2 este un #imediat, poate fi negativ
        // Ex: #12 => 12
        // Extragem valoarea
        if (op2[0] == '#') {
            int val = atoi(op2+1); // sare peste '#'
            unsigned int imm10 = to10BitSigned(val);
            // punem imm10 pe [9:0], DAR atenție – bitul 9 e deja folosit pentru X/Y
            // Conform enunțului: 
            //   [8:0] bits => valoare imediată
            //   bit9 => select registru X=0, Y=1 
            // însă la LDR/STR scrie că iau două argumente: (ex. LDR X, #12)
            // Prin definiție, bit 9 este deja "ocupat" de X/Y?
            // Enunțul zice: "9 bitul de selecție a registrului (X - 0, Y - 1), 
            // pentru instrucțiunile LDR, STR, INC, DEC și branch/jump trebuie să fie 1 mereu".
            // Aici e un pic de ambiguitate, dar exemplul dat de enunț e clar:
            //   LDR Y, #131 -> 1 11100 1 010000011
            // Acolo se vede: bit15=1, opcode=11100(28), bit9=1 (pentru Y), iar [8:0] = 10000011(131).
            // Deci lăsăm bit9 = 1/0 pt Y/X, iar [8:0] punem val mascat.
            unsigned int low9 = imm10 & 0x1FF;  // cei 9 biți de jos
            instr |= low9; // punem pe [8:0]
        } else {
            fprintf(stderr, "Eroare: LDR/STR fara # la al doilea argument ('%s')!\n", op2);
        }
    }
    // -------------------------------------------------
    // (PSH, POP) – 1 param: X, Y sau A
    //   - dacă e A => bit15=1
    //   - dacă e X sau Y => bit15=0
    // -------------------------------------------------
    else if (opcode == 30 || opcode == 31) {
        // PSH, POP
        int reg = whichRegister(op1);
        if (reg == 3) {
            // A => bit15=1
            bit15 = 1;
        } else if (reg == 1) {
            // X => bit15=0, bit9=0 => nimic
        } else if (reg == 2) {
            // Y => bit15=0, bit9=1
            instr |= (1 << 9);
        } else {
            fprintf(stderr, "Eroare: PSH/POP cu registru invalid '%s'!\n", op1);
        }
    }
    // -------------------------------------------------
    // 1 parametru - poate fi registru (X, Y, A) SAU #imediat SAU etichetă (pt branch)
    // Instrucțiile care intră aici: 
    //   ADD, SUB, LSR, LSL, RSR, RSL, MOV, MUL, DIV, MOD, AND, OR, XOR, NOT, CMP, TST
    //   (și BRZ, BNR, BRC, BRO, BRA, JMP ... cu mențiunea că ele oricum pun bit15=1)
    // -------------------------------------------------
    else {
        // Verificăm dacă e branch/jump => parametru poate fi #imediat / etichetă
        if (isBranchOrJump(opcode)) {
            // mereu bit15=1
            bit15 = 1;
            
            // Vedem dacă e #număr sau label
            if (op1[0] == '#') {
                // E un #imediat
                int val = atoi(op1 + 1);
                unsigned int imm10 = to10BitSigned(val);
                // punem pe [9:0]
                instr |= imm10 & 0x3FF;
            } else {
                // Presupunem că e etichetă
                if (isSecondPass) {
                    // Căutăm label în vectorul de labeluri
                    int found = 0;
                    int labelLine = 0;
                    for (int i=0; i<labelCount; i++){
                        if (strcasecmp(labels[i].labelName, op1) == 0){
                            found = 1;
                            labelLine = labels[i].instrIndex;
                            break;
                        }
                    }
                    if (!found) {
                        fprintf(stderr, "Eroare: label '%s' nedefinit!\n", op1);
                    } else {
                        // offset = labelLine - (currentLine + 1)
                        int offset = labelLine - (currentLine + 1);
                        unsigned int imm10 = to10BitSigned(offset);
                        instr |= imm10 & 0x3FF;
                    }
                }
                // Dacă nu suntem în al doilea pass, nu facem nimic
            }
        }
        else {
            // Instrucții normale cu 1 parametru
            // Poate fi #imediat sau registru X/Y/A
            // De ex: ADD #3, SUB X etc.
            int reg = whichRegister(op1);
            if (reg != 0) {
                // Avem parametru = registru
                // bit15=0 (implicit), punem bit9=0 pt X, bit9=1 pt Y
                // dar ce facem cu A? Enunțul nu detaliază exact la bit9
                // Se menționează doar X=0, Y=1. 
                // A nu apare oficial în specificația bit9, deci îl lăsăm 0.
                // Practic, dacă e A, punem bit9=0. (ex: MOV A, ? – e ambiguu, dar respectăm enunțul)
                if (reg == 2) {
                    // Y
                    instr |= (1 << 9);
                }
                else {
                    // X sau A => bit9=0
                }
            } else {
                // E #imediat?
                if (op1[0] == '#') {
                    bit15 = 1;
                    int val = atoi(op1 + 1);
                    unsigned int imm10 = to10BitSigned(val);
                    // bit9 face parte din [9:0], deci tot imm10
                    instr |= (imm10 & 0x3FF);
                }
                else {
                    // Altceva => teoretic un label? Dar enunțul nu spune că
                    // ADD, SUB etc. pot avea label. Deci semnalăm eroare.
                    fprintf(stderr, "Eroare: parametru necunoscut '%s' la instrucțiunea %d.\n", 
                            op1, opcode);
                }
            }
        }
    }

    // Final: setăm bitul 15 dacă e cazul
    if (bit15) {
        instr |= (1 << 15);
    }

    return instr;
}

// ---------------------------------------------------------------------
// Program principal
// Folosire: mini_asm_compiler input.asm output.bin
// ---------------------------------------------------------------------
int main(int argc, char *argv[])
{
    if (argc < 3) {
        fprintf(stderr, "Utilizare: %s <fisier_intrare> <fisier_iesire>\n", argv[0]);
        return 1;
    }

    FILE *fin = fopen(argv[1], "r");
    if (!fin) {
        fprintf(stderr, "Eroare la deschiderea fisierului de intrare '%s'!\n", argv[1]);
        return 1;
    }

    FILE *fout = fopen(argv[2], "w");
    if (!fout) {
        fprintf(stderr, "Eroare la deschiderea fisierului de iesire '%s'!\n", argv[2]);
        fclose(fin);
        return 1;
    }

    Instruction program[MAX_PROG_LEN];
    Label labelTable[MAX_LABELS];
    int instrCount = 0;
    int labelCount = 0;

    // -----------------------------------------------------------------
    // FAZA 1: citim linie cu linie, extragem eventual label + mnemonic + op1 + op2
    // -----------------------------------------------------------------
    char line[MAX_LINE_LEN];
    int lineNumber = 0;
    while (fgets(line, sizeof(line), fin)) {
        // Ștergem comentariile (dacă apar, de ex. cu ';' sau '//')
        // (Opcional, depinde cum doriți să tratați comentariile)
        // Pentru simplitate ignorăm orice text după ';'
        char *p = strchr(line, ';');
        if (p) *p = '\0';

        // Curățăm spațiile de la început
        while (isspace((unsigned char)*line)) {
            memmove(line, line+1, strlen(line));
        }
        // Eliminăm \n de la final
        p = strchr(line, '\n');
        if (p) *p = '\0';

        // Dacă e linie goală, sărim
        if (strlen(line) == 0) {
            continue;
        }

        // Inițializăm intrarea de program
        strcpy(program[instrCount].label, "");
        strcpy(program[instrCount].mnemonic, "");
        strcpy(program[instrCount].op1, "");
        strcpy(program[instrCount].op2, "");
        program[instrCount].lineNumber = instrCount;
        program[instrCount].hasLabel = 0;

        // Verificăm dacă există un label, ex: start:
        char *colonPos = strchr(line, ':');
        if (colonPos) {
            // Avem label
            // Citim tot ce e înainte de ':'
            *colonPos = '\0'; 
            // ce rămâne e numele labelului
            strcpy(program[instrCount].label, line);
            program[instrCount].hasLabel = 1;

            // Adăugăm în tabela de label
            strcpy(labelTable[labelCount].labelName, line);
            labelTable[labelCount].instrIndex = instrCount;
            labelCount++;

            // Trecem mai departe la ce urmează după ':'
            colonPos++;
            while (isspace((unsigned char)*colonPos)) colonPos++;
            // restul de text e mnemonic + parametri
            strcpy(line, colonPos);
        }

        // Acum citim mnemonic + parametri (maxim 2)
        // Mai întâi luăm primul token ca mnemonic
        char mnemonic[16] = "";
        char operand1[64] = "";
        char operand2[64] = "";

        char *token = strtok(line, " \t,");
        if (token) {
            strcpy(mnemonic, token);
            // uppercase/lowercase unify:
            for (char *pp = mnemonic; *pp; pp++) *pp = toupper((unsigned char)*pp);
        }
        token = strtok(NULL, " \t,");
        if (token) {
            strcpy(operand1, token);
            for (char *pp = operand1; *pp; pp++) *pp = toupper((unsigned char)*pp);
        }
        token = strtok(NULL, " \t,");
        if (token) {
            strcpy(operand2, token);
            for (char *pp = operand2; *pp; pp++) *pp = toupper((unsigned char)*pp);
        }

        // Salvăm în program
        strcpy(program[instrCount].mnemonic, mnemonic);
        strcpy(program[instrCount].op1, operand1);
        strcpy(program[instrCount].op2, operand2);

        instrCount++;
        lineNumber++;
    }

    fclose(fin);

    // -----------------------------------------------------------------
    // FAZA 2: generăm codul mașină, rezolvând etichetele la a doua trecere
    // -----------------------------------------------------------------
    for (int i = 0; i < instrCount; i++) {
        int opcode = getOpcode(program[i].mnemonic);
        if (opcode < 0) {
            fprintf(stderr, "Eroare: mnemonic necunoscut '%s' la linia %d\n",
                    program[i].mnemonic, i);
            continue;
        }

        unsigned short machineCode = assembleInstruction(
            opcode,
            program[i].op1,
            program[i].op2,
            /* currentLine = */ i,
            /* isSecondPass = */ 1,
            labelTable,
            labelCount,
            program,
            instrCount
        );

        // Scriem în fișier în format binar (16 biți)
        // Fiecare instrucțiune pe o linie (ex: 1001110000000001)
        char outBuff[17];
        outBuff[16] = '\0';
        for (int b = 15; b >= 0; b--) {
            outBuff[15 - b] = (machineCode & (1 << b)) ? '1' : '0';
        }
        fprintf(fout, "%s\n", outBuff);
    }

    fclose(fout);

    return 0;
}