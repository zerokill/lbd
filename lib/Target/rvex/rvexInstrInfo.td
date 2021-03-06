//===- rvexInstrInfo.td - Target Description for rvex Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the rvex implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

include "rvexInstrFormats.td"

//===----------------------------------------------------------------------===//
// rvex profiles and nodes
//===----------------------------------------------------------------------===//

def SDT_rvexRet  : SDTypeProfile<0, 3, [SDTCisSameAs<0, 1>,
                                       SDTCisSameAs<1, 2>,
                                       SDTCisInt<1>]>;

def SDT_rvexDivRem        : SDTypeProfile<0, 2,
                                          [SDTCisInt<0>,
                                          SDTCisSameAs<0, 1>]>;                                      

def SDT_MipsJmpLink      : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_slct              : SDTypeProfile<1, 3, []>;

// Type profile for add carry generate instruction
// (outs result, carry), (ins ra, rb, carry_in)
def SDT_rvexAddc          : SDTypeProfile<2, 3, 
                                          [//SDTCisVT<0, i32>, 
                                          //SDTCisVT<1, i1>,
                                          SDTCisSameAs<0, 2>,
                                          SDTCisSameAs<0, 3>,
                                          SDTCisInt<0>, SDTCisVT<0, i32>,
                                          SDTCisSameAs<1,4>,
                                          SDTCisInt<1>, SDTCisVT<1, i1>]>;
                                          //SDTCisOpSmallerThanOp<1,2>,
                                          //SDTCisOpSmallerThanOp<1,3>,
                                          //SDTCisOpSmallerThanOp<4,0>]>;                                          

def SDT_rvexCallSeqStart  : SDCallSeqStart<[SDTCisVT<0, i32>]>;
def SDT_rvexCallSeqEnd    : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;

// Call
// Call
def MipsJmpLink : SDNode<"rvexISD::JmpLink",SDT_MipsJmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;

// Hi and Lo nodes are used to handle global addresses. Used on
// rvexISelLowering to lower stuff like GlobalAddress, ExternalSymbol
// static model. (nothing to do with rvex Registers Hi and Lo)
def rvexGPRel             : SDNode<"rvexISD::GPRel", SDTIntUnaryOp>;

def SDT_LE1Ret  : SDTypeProfile<0, 3, [SDTCisSameAs<0, 1>,
                                       SDTCisSameAs<1, 2>,
                                       SDTCisInt<1>]>;

// Return
def rvexRet               : SDNode<"rvexISD::Ret", SDT_LE1Ret, 
                                          [SDNPHasChain,
                                          SDNPOptInGlue, SDNPVariadic]>;

// These are target-independent nodes, but have target-specific formats.
def callseq_start         : SDNode<"ISD::CALLSEQ_START", SDT_rvexCallSeqStart,
                                          [SDNPHasChain, SDNPOutGlue]>;
def callseq_end           : SDNode<"ISD::CALLSEQ_END", SDT_rvexCallSeqEnd,
                                          [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def rvexSlct              : SDNode<"rvexISD::Slct", SDT_slct>;

def rvexAddc              : SDNode<"rvexISD::Addc", SDT_rvexAddc>;
def rvexAdde              : SDNode<"rvexISD::Adde", SDT_rvexAddc>;

def rvexDivs              : SDNode<"rvexISD::Divs", SDT_rvexAddc>;

def rvexMpyllu            : SDNode<"rvexISD::Mpyllu", SDTIntBinOp, []>;
def rvexMpylhu            : SDNode<"rvexISD::Mpylhu", SDTIntBinOp, []>;
def rvexMpyhhu            : SDNode<"rvexISD::Mpyhhu", SDTIntBinOp, []>;
def rvexMpyll             : SDNode<"rvexISD::Mpyll", SDTIntBinOp, []>;
def rvexMpylh             : SDNode<"rvexISD::Mpylh", SDTIntBinOp, []>;
def rvexMpyhh             : SDNode<"rvexISD::Mpyhh", SDTIntBinOp, []>;
def rvexMpyl              : SDNode<"rvexISD::Mpyhh", SDTIntBinOp, []>;
def rvexMpyh              : SDNode<"rvexISD::Mpyhh", SDTIntBinOp, []>;

def rvexSXTB              : SDNode<"rvexISD::SXTB", SDTExtInreg, []>;
def rvexSXTH              : SDNode<"rvexISD::SXTH", SDTExtInreg, []>;
def rvexZXTB              : SDNode<"rvexISD::ZXTB", SDTExtInreg, []>;                              
def rvexZXTH              : SDNode<"rvexISD::ZXTH", SDTExtInreg, []>;


//===----------------------------------------------------------------------===//
// rvex Operand, Complex Patterns and Transformations Definitions.
//===----------------------------------------------------------------------===//

// Instruction operand types
def brtarget    : Operand<OtherVT> {
  let EncoderMethod = "getBranchTargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranchTarget";
}

def calltarget  : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}

// Signed Operand
def simm8      : Operand<i32> {
  let DecoderMethod= "DecodeSimm8";
}

def shamt       : Operand<i32>;

// Unsigned Operand
def uimm8      : Operand<i32> {
  let PrintMethod = "printUnsignedImm";
}

// Address operand
def mem : Operand<i32> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops CPURegs, simm8);
  let EncoderMethod = "getMemEncoding";
}

def mem_ea : Operand<i32> {
  let PrintMethod = "printMemOperandEA";
  let MIOperandInfo = (ops CPURegs, simm8);
  let EncoderMethod = "getMemEncoding";
}

// Node immediate fits as 16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt32  : PatLeaf<(imm), [{ return isInt<32>(N->getSExtValue()); }]>;
def immSExt8  : PatLeaf<(imm), [{ return isInt<8>(N->getSExtValue()); }]>;

// Node immediate fits as 16-bit zero extended on target immediate.
// The LO16 param means that only the lower 16 bits of the node
// immediate are caught.
// e.g. addiu, sltiu
def immZExt16  : PatLeaf<(imm), [{
  if (N->getValueType(0) == MVT::i32)
    return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
  else
    return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}]>;

// rvex Address Mode! SDNode frameindex could possibily be a match
// since load and store instructions from stack used it.
def ADDRrr : ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], [SDNPWantParent]>;

//===----------------------------------------------------------------------===//
// Pattern fragment for load/store
//===----------------------------------------------------------------------===//

class AlignedLoad<PatFrag Node> :
  PatFrag<(ops node:$ptr), (Node node:$ptr), [{
  LoadSDNode *LD = cast<LoadSDNode>(N);
  return LD->getMemoryVT().getSizeInBits()/8 <= LD->getAlignment();
}]>;

class AlignedStore<PatFrag Node> :
  PatFrag<(ops node:$val, node:$ptr), (Node node:$val, node:$ptr), [{
  StoreSDNode *SD = cast<StoreSDNode>(N);
  return SD->getMemoryVT().getSizeInBits()/8 <= SD->getAlignment();
}]>;

// Load/Store PatFrags.
def sextloadi16_a   : AlignedLoad<sextloadi16>;
def zextloadi16_a   : AlignedLoad<zextloadi16>;
def extloadi16_a    : AlignedLoad<extloadi16>;
def load_a          : AlignedLoad<load>;
def truncstorei16_a : AlignedStore<truncstorei16>;
def store_a         : AlignedStore<store>;

//===----------------------------------------------------------------------===//
// Instructions specific format
//===----------------------------------------------------------------------===//

// Arithmetic and logical instructions with 2 register operands.
class ReturnLogic<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC> :
  FL<op, (outs RC:$ra), (ins RC:$rb, Od:$imm8, RC:$rc),
     !strconcat(instr_asm, "\t$ra = $rb, $imm8, $rc"),
     [], IIAlu, TypeIIAlu> {
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands.
class ArithLogicR<bits<8> op, string instr_asm, SDNode OpNode,
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins RC:$rb, RC:$rc),
     !strconcat(instr_asm, "\t$ra = $rb, $rc"),
     [(set RC:$ra, (OpNode RC:$rb, RC:$rc))], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 2 register operands.
class ArithLogicI<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC> :
  FL<op, (outs RC:$ra), (ins RC:$rb, Od:$imm8),
     !strconcat(instr_asm, "\t$ra = $rb, $imm8"),
     [(set RC:$ra, (OpNode RC:$rb, immSExt8:$imm8))], IIAlu, TypeIIAlu> {
  let isCommutable = 0;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 2 register operands.
class ArithLogicIS<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC> :
  FL<op, (outs RC:$ra), (ins RC:$rb, Od:$imm8),
     !strconcat(instr_asm, "\t$ra = $imm8"),
     [/*(set RC:$ra, (OpNode RC:$rb, immSExt8:$imm8))*/], IIAlu, TypeIIAlu> {
  let isCommutable = 0;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands and 2 returns.
// Used for ADDCG and DIVS
class ArithLogicC<bits<8> op, string instr_asm, SDNode OpNode,
                  InstrItinClass itin, RegisterClass RC, RegisterClass BRRegs, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra, BRRegs:$co), (ins RC:$rb, RC:$rc, BRRegs:$ci),
     !strconcat(instr_asm, "\t$ra, $co = $rb, $rc, $ci"),
     [/*(set RC:$ra, (OpNode RC:$rb, RC:$rc, RC:$ci))*/], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic instructions with no pattern
class ArithLogicS<bits<8> op, string instr_asm,
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins RC:$rb, RC:$rc),
     !strconcat(instr_asm, "\t$ra = $rb, $rc"),
     [], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands.
class ArithLogicSi<bits<8> op, string instr_asm,
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins RC:$rb, i32imm:$rc),
     !strconcat(instr_asm, "\t$ra = $rb, $rc"),
     [], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic instructions with no pattern
class ArithLogicS1<bits<8> op, string instr_asm,
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins RC:$rb),
     !strconcat(instr_asm, "\t$ra = $rb"),
     [], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Move immediate imm8 to register ra.
class MoveImm<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC> :
  FL<op, (outs RC:$ra), (ins RC:$rb, Od:$imm),
     !strconcat(instr_asm, "\t$ra = $imm"),
     [], IIAlu, TypeIIAlu> {
  let rb = 0;
  let isReMaterializable = 1;
}

// Move immediate imm8 to register ra.
class MoveImmSmall<bits<8> op, string instr_asm, SDNode OpNode,
                  Operand Od, PatLeaf imm_type, RegisterClass RC> :
  FL<op, (outs RC:$ra), (ins RC:$rb, Od:$imm),
     !strconcat(instr_asm, "\t$ra = $imm"),
     [], IIAlu, TypeIIAlu> {
  let rb = 0;
  let isReMaterializable = 1;
}

// Shifts
class shift_rotate_imm<bits<8> op, bits<4> isRotate, string instr_asm,
                       SDNode OpNode, Operand ImmOpnd,
                       RegisterClass RC>:
  FA<op, (outs RC:$ra), (ins RC:$rb, RC:$shamt),
     !strconcat(instr_asm, "\t$ra = $rb, $shamt"),
     [(set RC:$ra, (OpNode RC:$rb, RC:$shamt))], IIAlu, TypeIIAlu> {
  let rc = isRotate;
  let shamt = shamt;
}

// 32-bit shift instructions.
class shift_rotate_imm32<bits<8> func, bits<4> isRotate, string instr_asm,
                         SDNode OpNode>:
  shift_rotate_imm<func, isRotate, instr_asm, OpNode, shamt, CPURegs>;

class FMem<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
          InstrItinClass itin, CType type>: FL<op, outs, ins, asmstr, pattern, itin, type> {
  bits<20> addr;
  let Inst{19-16} = addr{19-16};
  let Inst{15-0}  = addr{15-0};
  let DecoderMethod = "DecodeMem";
}

// Memory Load/Store
let canFoldAsLoad = 1 in
class LoadM<bits<8> op, string instr_asm, PatFrag OpNode, RegisterClass RC,
            Operand MemOpnd, bit Pseudo>:
  FMem<op, (outs RC:$ra), (ins MemOpnd:$addr),
     !strconcat(instr_asm, "\t$ra = $addr"),
     [(set RC:$ra, (OpNode ADDRrr:$addr))], IILoadStore, TypeIILoadStore> {
  let isPseudo = Pseudo;
}

class StoreM<bits<8> op, string instr_asm, PatFrag OpNode, RegisterClass RC,
             Operand MemOpnd, bit Pseudo>:
  FMem<op, (outs), (ins RC:$ra, MemOpnd:$addr),
     !strconcat(instr_asm, "\t$addr = $ra"),
     [(OpNode RC:$ra, ADDRrr:$addr)], IILoadStore, TypeIILoadStore> {
  let isPseudo = Pseudo;
}

// 32-bit load.
multiclass LoadM32<bits<8> op, string instr_asm, PatFrag OpNode,
                   bit Pseudo = 0> {
  def #NAME# : LoadM<op, instr_asm, OpNode, CPURegs, mem, Pseudo>;
}

// 32-bit store.
multiclass StoreM32<bits<8> op, string instr_asm, PatFrag OpNode,
                    bit Pseudo = 0> {
  def #NAME# : StoreM<op, instr_asm, OpNode, CPURegs, mem, Pseudo>;
}

// Arithmetic and logical instructions with 3 register operands and 2 returns.
// Used for ADDCG and DIVS
class SelectRR<bits<8> op, string instr_asm, SDNode OpNode,
                  InstrItinClass itin, RegisterClass RC, RegisterClass BRRegs, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins BRRegs:$ci, RC:$rb, RC:$rc),
     !strconcat(instr_asm, "\t$ra = $ci, $rb, $rc"),
     [(set RC:$ra, (OpNode BRRegs:$ci, RC:$rb, RC:$rc))], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 3 register operands and 2 returns.
// Used for ADDCG and DIVS
class SelectRI<bits<8> op, string instr_asm, SDNode OpNode,
                  InstrItinClass itin, RegisterClass RC, RegisterClass BRRegs, bit isComm = 0, CType type>:
  FA<op, (outs RC:$ra), (ins BRRegs:$ci, RC:$rb, i32imm:$rc),
     !strconcat(instr_asm, "\t$ra = $ci, $rb, $rc"),
     [(set RC:$ra, (OpNode BRRegs:$ci, RC:$rb, imm:$rc))], itin, type> {
  let shamt = 0;
  let isCommutable = isComm;  // e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}



// Unconditional branch, such as JMP
class UncondBranch<bits<8> op, string instr_asm>:
  FJ<op, (outs), (ins brtarget:$addr),
             !strconcat(instr_asm, "\t$addr"), [(br bb:$addr)], IIBranch, TypeIIBranch> {
  let isBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
  let hasDelaySlot = 0;
  let DecoderMethod = "DecodeJumpRelativeTarget";
}

// Jump and Link (Call)
let isCall=1, hasDelaySlot=0 in {
  class JumpLink<bits<8> op, string instr_asm>:
    FJ<op, (outs), (ins CPURegs:$link, calltarget:$target),
       !strconcat(instr_asm, "\t$link = $target"), [],
       IIBranch, TypeIIBranch> {
       }

  class JumpLinkReg<bits<8> op, string instr_asm,
                    RegisterClass RC>:
    FA<op, (outs), (ins RC:$rb, RC:$rc, variable_ops),
       !strconcat(instr_asm, "\t$rb = $rc"), [], IIBranch, TypeIIBranch> {
    let rc = 0;
    let ra = 14;
    let shamt = 0;
  }
}

// Mul, Div
class Mult<bits<8> op, string instr_asm, InstrItinClass itin,
           RegisterClass RC>:
  FL<op, (outs RC:$res), (ins RC:$ra, RC:$rb),
     !strconcat(instr_asm, "\t$res = $ra, $rb"), [], itin, TypeIIImul> {
  let imm8 = 0;
  let isCommutable = 1;
  let neverHasSideEffects = 1;
}

class Mult32<bits<8> op, string instr_asm, InstrItinClass itin>:
  Mult<op, instr_asm, itin, CPURegs>;

class EffectiveAddress<string instr_asm, RegisterClass RC, Operand Mem> :
  FMem<0x09, (outs RC:$ra), (ins Mem:$addr),
     instr_asm, [(set RC:$ra, ADDRrr:$addr)], IIAlu, TypeIIAlu>;

//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//

// As stack alignment is always done with addiu, we need a 16-bit immediate
let Defs = [R1], Uses = [R1] in {
def ADJCALLSTACKDOWN : rvexPseudo<(outs), (ins uimm8:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : rvexPseudo<(outs), (ins uimm8:$amt1, uimm8:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}     

//===----------------------------------------------------------------------===//
// Instruction definition
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// rvexI Instructions
//===----------------------------------------------------------------------===//

/// Load and Store Instructions
///  aligned
defm LD         : LoadM32<0x00,  "ldw ",  load_a>;
defm ST         : StoreM32<0x01, "stw ",  store_a>;
defm LB         : LoadM32<0x03, "ldb ",  sextloadi8>;
defm LBu        : LoadM32<0x04, "ldbu", zextloadi8>;
defm SB         : StoreM32<0x05, "stb ", truncstorei8>;
defm LH         : LoadM32<0x06, "ldh ",  sextloadi16_a>;
defm LHu        : LoadM32<0x07, "ldhu", zextloadi16_a>;
defm SH         : StoreM32<0x08, "sth ", truncstorei16_a>;

/// Arithmetic Instructions (ALU Immediate)


def MOV         : MoveImm<0x09, "mov ", add, simm8, immSExt32, CPURegs>;
def MOVS        : MoveImmSmall<0x09, "mov ", add, simm8, immSExt8, CPURegs>;




def ADDiu       : ArithLogicI<0x09, "add ", add, simm8, immSExt8, CPURegs>;

def XORiu       : ArithLogicR<0x1A, "xor ", xor, IIAlu, CPURegs, 1, TypeIIAlu>;

//Imm types
def ANDi        : ArithLogicI<0x09, "and ", and, simm8, immSExt8, CPURegs>;
def ORi         : ArithLogicI<0x09, "or  ", or, simm8, immSExt8, CPURegs>;
def XORi        : ArithLogicI<0x09, "xor ", xor, simm8, immSExt8, CPURegs>;

let isReturn=1 in
def RETURN      : ReturnLogic<0x09, "return", add, simm8, immSExt8, CPURegs>;

/// Arithmetic Instructions (3-Operand, R-Type)
def ADD         : ArithLogicR<0x13, "add ", add, IIAlu, CPURegs, 1, TypeIIAlu>;
def SUB         : ArithLogicR<0x14, "sub ", sub, IIAlu, CPURegs, 1, TypeIIAlu>;
def AND         : ArithLogicR<0x18, "and ", and, IIAlu, CPURegs, 1, TypeIIAlu>;
def OR          : ArithLogicR<0x19, "or  ", or, IIAlu, CPURegs, 1, TypeIIAlu>;
def XOR         : ArithLogicR<0x1A, "xor ", xor, IIAlu, CPURegs, 1, TypeIIAlu>;

def rvexORC     : SDNode<"rvexISD::Orc", SDTIntBinOp, []>;
def rvexMAX     : SDNode<"rvexISD::Max", SDTIntBinOp, []>;
def rvexMAXU    : SDNode<"rvexISD::Maxu", SDTIntBinOp, []>;
def rvexMIN     : SDNode<"rvexISD::Min", SDTIntBinOp, []>;
def rvexMINU    : SDNode<"rvexISD::Minu", SDTIntBinOp, []>;
def ORC         : ArithLogicR<0x1A, "orc ", rvexORC, IIAlu, CPURegs, 0, TypeIIAlu>;
def MAX         : ArithLogicR<0x1A, "max ", rvexMAX, IIAlu, CPURegs, 1, TypeIIAlu>;
def MAXU        : ArithLogicR<0x1A, "maxu", rvexMAXU, IIAlu, CPURegs, 1, TypeIIAlu>;
def MIN         : ArithLogicR<0x1A, "min ", rvexMIN, IIAlu, CPURegs, 1, TypeIIAlu>;
def MINU        : ArithLogicR<0x1A, "minu", rvexMINU, IIAlu, CPURegs, 1, TypeIIAlu>;

def SLCTrr      : SelectRR<1, "slct", select, IIAlu, CPURegs, BRRegs, 0, TypeIIAlu>;
def SLCTri      : SelectRI<1, "slct", select, IIAlu, CPURegs, BRRegs, 0, TypeIIAlu>;

def SLCT        : SelectRR<0x1A, "slct", rvexSlct, IIAlu, CPURegs, BRRegs, 1, TypeIIAlu>;

def rvexDIVS    : ArithLogicC<0x13, "divs ", rvexDivs, IIAlu, CPURegs, BRRegs, 1, TypeIIAlu>;

def rvexADDC    : ArithLogicC<0x13, "addcg", rvexAddc, IIAlu, CPURegs, BRRegs, 1, TypeIIAlu>;
def rvexADDE    : ArithLogicC<0x13, "addcg", rvexAddc, IIAlu, CPURegs, BRRegs, 1, TypeIIAlu>;

def rvexMPYLLU  : ArithLogicR<0x1A, "mpyllu ", rvexMpyllu, IIImul, CPURegs, 1, TypeIIImul>;
def rvexMPYLHU  : ArithLogicR<0x1A, "mpylhu ", rvexMpylhu, IIImul, CPURegs, 0, TypeIIImul>;
def rvexMPYHHU  : ArithLogicR<0x1A, "mpyhhu ", rvexMpyhhu, IIImul, CPURegs, 1, TypeIIImul>;
def rvexMPYLL   : ArithLogicR<0x1A, "mpyll ", rvexMpyll, IIImul, CPURegs, 1, TypeIIImul>;
def rvexMPYLH   : ArithLogicR<0x1A, "mpylh ", rvexMpylh, IIImul, CPURegs, 0, TypeIIImul>;
def rvexMPYHH   : ArithLogicR<0x1A, "mpyhh ", rvexMpyhh, IIImul, CPURegs, 1, TypeIIImul>;
def rvexMPYL    : ArithLogicR<0x1A, "mpyl ", rvexMpyl, IIImul, CPURegs, 1, TypeIIImul>;
def rvexMPYH    : ArithLogicR<0x1A, "mpyh ", rvexMpyh, IIImul, CPURegs, 1, TypeIIImul>;

def SH1ADD      : ArithLogicS<0x13, "sh1add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH2ADD      : ArithLogicS<0x13, "sh2add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH3ADD      : ArithLogicS<0x13, "sh3add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH4ADD      : ArithLogicS<0x13, "sh4add ", IIAlu, CPURegs, 0, TypeIIAlu>;

def SH1ADDi     : ArithLogicSi<0x13, "sh1add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH2ADDi     : ArithLogicSi<0x13, "sh2add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH3ADDi     : ArithLogicSi<0x13, "sh3add ", IIAlu, CPURegs, 0, TypeIIAlu>;
def SH4ADDi     : ArithLogicSi<0x13, "sh4add ", IIAlu, CPURegs, 0, TypeIIAlu>;

def SXTB        : ArithLogicS1<0x13, "sxtb", IIAlu, CPURegs, 0, TypeIIAlu>;
def SXTH        : ArithLogicS1<0x13, "sxth", IIAlu, CPURegs, 0, TypeIIAlu>;
def ZXTB        : ArithLogicS1<0x13, "zxtb", IIAlu, CPURegs, 0, TypeIIAlu>;
def ZXTH        : ArithLogicS1<0x13, "zxth", IIAlu, CPURegs, 0, TypeIIAlu>;


// Operations to load/store predicate register


let Defs = [R63] in {
  def LDW_PRED  : rvexPseudo<(outs BRRegs:$dst), (ins mem:$addr),
                            "!LOADPRED $dst", []>;
  def STW_PRED  : rvexPseudo<(outs), (ins BRRegs:$src, mem:$addr),
                            "!STOREPRED $src", []>;
}

// Extending Patterns
def : Pat<(sra (shl CPURegs:$src, (i32 16)), (i32 16)),
          (SXTH CPURegs:$src)>;
def : Pat<(sra (shl CPURegs:$src, (i32 24)), (i32 24)),
          (SXTB CPURegs:$src)>;
def : Pat<(srl (shl CPURegs:$src, (i32 16)), (i32 16)),
          (ZXTH CPURegs:$src)>;
def : Pat<(srl (shl CPURegs:$src, (i32 24)), (i32 24)),
          (ZXTB CPURegs:$src)>;
def : Pat<(and CPURegs:$src, (i32 0x000000FF)),
          (ZXTB CPURegs:$src)>;
def : Pat<(and CPURegs:$src, (i32 0x0000FFFF)),
          (ZXTH CPURegs:$src)>;

// Extend in reg patterns
def : Pat<(sext_inreg CPURegs:$src, i8),
          (SXTB CPURegs:$src)>;
def : Pat<(sext_inreg CPURegs:$src, i16),
          (SXTH CPURegs:$src)>;

def MULT        : Mult32<0x50, "mpylu", IIImul>;
def MULTu       : Mult32<0x51, "mpyhs", IIImul>;

/// Shift Instructions
// work, sra for ashr llvm IR instruction
def SRA         : shift_rotate_imm32<0x1B, 0x00, "shr ", sra>;
def SHL         : shift_rotate_imm32<0x1E, 0x00, "shl ", shl>;
def SHR         : shift_rotate_imm32<0x1F, 0x00, "shru", srl>;

    

// Conditional Branch
class CBranch<bits<8> op, string instr_asm, RegisterClass RC>:
  FJ<op, (outs), (ins RC:$ra, brtarget:$addr),
             !strconcat(instr_asm, "\t$ra, $addr"),
             [(brcond RC:$ra, bb:$addr)], IIBranch, TypeIIBranch> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 0;
  let neverHasSideEffects = 1;
}      


def BR          : CBranch<0x25, "br  ", BRRegs>;
def BRF         : CBranch<0x25, "brf ", BRRegs>;



def JMP         : UncondBranch<0x26, "goto">;

/// Jump and Branch Instructions
let isCall=1, isBarrier=1 in
def CALL        : JumpLink<0x2B, "call">;
def JALR        : JumpLinkReg<0x2E, "call", CPURegs>;


let isReturn=1, isTerminator=1, hasDelaySlot=1, isCodeGenOnly=1,
    isBarrier=1, hasCtrlDep=1, addr=0 in
  def RET   : FJ <0x2C, (outs), (ins CPURegs:$src, i32imm:$frame, CPURegs:$lnk),
                "return\t$src = $src, $frame, $lnk", [(rvexRet CPURegs:$src, imm:$frame, CPURegs:$lnk)], IIBranch, TypeIIBranch>;
                //"return l0.0", [(rvexRet CPURegs:$target)], IIBranch, TypeIIBranch>;

//def : Pat<(rvexRet CPURegs:$target), (RET CPURegs:$target, 0x8)>;



/// No operation
let addr=0 in
  def NOP   : FJ<0, (outs), (ins), "nop", [], IIAlu, TypeIIAlu>;


  
// FrameIndexes are legalized when they are operands from load/store
// instructions. The same not happens for stack address copies, so an
// add op with mem ComplexPattern is used and the stack address copy
// can be matched. It's similar to Sparc LEA_ADDRi
def LEA_ADDiu : EffectiveAddress<"add \t$ra = $addr", CPURegs, mem_ea> {
  let isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
//  Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//

// Small immediates
def : Pat<(i32 immSExt8:$in),
          (MOVS R0, immSExt8:$in)>;

def : Pat<(i32 imm:$in),
          (MOV R0, imm:$in)>;
          
//FIXME is dit nodig?
def : Pat<(MipsJmpLink (i32 tglobaladdr:$dst)),
          (CALL LR, tglobaladdr:$dst)>;
def : Pat<(MipsJmpLink (i32 texternalsym:$dst)),
          (CALL LR, texternalsym:$dst)>;          
def : Pat<(MipsJmpLink CPURegs:$rb),
          (JALR LR, CPURegs:$rb)>;
        
         
// gp_rel relocs
def : Pat<(add CPURegs:$gp, (rvexGPRel tglobaladdr:$in)),
          (ADDiu CPURegs:$gp, tglobaladdr:$in)>;

def : Pat<(not CPURegs:$in),
          (XORi CPURegs:$in, -1)>;

// Shift add patterns
def : Pat<(add (shl CPURegs:$lhs, (i32 1)), CPURegs:$rhs),
          (SH1ADD CPURegs:$lhs, CPURegs:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 2)), CPURegs:$rhs),
          (SH2ADD CPURegs:$lhs, CPURegs:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 3)), CPURegs:$rhs),
          (SH3ADD CPURegs:$lhs, CPURegs:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 4)), CPURegs:$rhs),
          (SH4ADD CPURegs:$lhs, CPURegs:$rhs)>; 

// Shift add immediate patterns
def : Pat<(add (shl CPURegs:$lhs, (i32 1)), imm:$rhs),
          (SH1ADDi CPURegs:$lhs, imm:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 2)), imm:$rhs),
          (SH2ADDi CPURegs:$lhs, imm:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 3)), imm:$rhs),
          (SH3ADDi CPURegs:$lhs, imm:$rhs)>; 
def : Pat<(add (shl CPURegs:$lhs, (i32 1)), imm:$rhs),
          (SH4ADDi CPURegs:$lhs, imm:$rhs)>;                                                    

// FIXME mult pattern
def : Pat<(mul CPURegs:$rb, CPURegs:$rc),
              (ADD (MULT CPURegs:$rb, CPURegs:$rc), (MULTu CPURegs:$rb, CPURegs:$rc))>;          

def : Pat<(i32 (extloadi1  ADDRrr:$src)), (LBu ADDRrr:$src)>;
def : Pat<(i32 (extloadi8  ADDRrr:$src)), (LBu ADDRrr:$src)>;
def : Pat<(i32 (extloadi16_a ADDRrr:$src)), (LHu ADDRrr:$src)>;



// Comparisons
let isReMaterializable = 1, neverHasSideEffects = 1 in
class SetCCR<string instr_asm, PatFrag cond_op, RegisterClass DestRegs>:
      FA<0, (outs DestRegs:$res), (ins CPURegs:$lhs, CPURegs:$rhs),
      !strconcat(instr_asm, "  $res, $lhs, $rhs"),
      [(set DestRegs:$res, (cond_op CPURegs:$lhs, CPURegs:$rhs))], IIAlu, TypeIIAlu>;

let isReMaterializable = 1, neverHasSideEffects = 1 in
class SetCCI<string instr_asm, PatFrag cond_op, RegisterClass DestRegs>:
      FL<0, (outs DestRegs:$res), (ins CPURegs:$lhs, i32imm:$rhs),
      !strconcat(instr_asm, "  $res, $lhs, $rhs"),
      [(set DestRegs:$res, (cond_op CPURegs:$lhs, imm:$rhs))], IIAlu, TypeIIAlu>;


let isCompare = 1 in {




  def CMPEQ     : SetCCR<"cmpeq ", seteq, BRRegs>;
  def CMPGE     : SetCCR<"cmpge ", setge, BRRegs>;
  def CMPGEU    : SetCCR<"cmpgeu", setuge, BRRegs>;
  def CMPGT     : SetCCR<"cmpgt ", setgt, BRRegs>;
  def CMPGTU    : SetCCR<"cmpgtu", setugt, BRRegs>;
  def CMPLE     : SetCCR<"cmple ", setle, BRRegs>;
  def CMPLEU    : SetCCR<"cmpleu", setule, BRRegs>;
  def CMPLT     : SetCCR<"cmplt ", setlt, BRRegs>;
  def CMPLTU    : SetCCR<"cmpltu", setult, BRRegs>;
  def CMPNE     : SetCCR<"cmpne ", setne, BRRegs>;

  def CMPEQi    : SetCCI<"cmpeq ", seteq, BRRegs>;
  def CMPGEi    : SetCCI<"cmpge ", setge, BRRegs>;
  def CMPGEUi   : SetCCI<"cmpgeu", setuge, BRRegs>;
  def CMPGTi    : SetCCI<"cmpgt ", setgt, BRRegs>;
  def CMPGTUi   : SetCCI<"cmpgtu", setugt, BRRegs>;
  def CMPLEi    : SetCCI<"cmple ", setle, BRRegs>;
  def CMPLEUi   : SetCCI<"cmpleu", setule, BRRegs>;
  def CMPLTi    : SetCCI<"cmplt ", setlt, BRRegs>;
  def CMPLTUi   : SetCCI<"cmpltu", setult, BRRegs>;
  def CMPNEi    : SetCCI<"cmpne ", setne, BRRegs>;  

  def CMPEQr    : SetCCR<"cmpeq ", seteq, CPURegs>;
  def CMPGEr    : SetCCR<"cmpge ", setge, CPURegs>;
  def CMPGEUr   : SetCCR<"cmpgeu", setuge, CPURegs>;
  def CMPGTr    : SetCCR<"cmpgt ", setgt, CPURegs>;
  def CMPGTUr   : SetCCR<"cmpgtu", setugt, CPURegs>;
  def CMPLEr    : SetCCR<"cmple ", setle, CPURegs>;
  def CMPLEUr   : SetCCR<"cmpleu", setule, CPURegs>;
  def CMPLTr    : SetCCR<"cmplt ", setlt, CPURegs>;
  def CMPLTUr   : SetCCR<"cmpltu", setult, CPURegs>;
  def CMPNEr    : SetCCR<"cmpne ", setne, CPURegs>;

  def CMPEQri   : SetCCI<"cmpeq ", seteq, CPURegs>;
  def CMPGEri   : SetCCI<"cmpge ", setge, CPURegs>;
  def CMPGEUri  : SetCCI<"cmpgeu", setuge, CPURegs>;
  def CMPGTri   : SetCCI<"cmpgt ", setgt, CPURegs>;
  def CMPGTUri  : SetCCI<"cmpgtu", setugt, CPURegs>;
  def CMPLEri   : SetCCI<"cmple ", setle, CPURegs>;
  def CMPLEUri  : SetCCI<"cmpleu", setule, CPURegs>;
  def CMPLTri   : SetCCI<"cmplt ", setlt, CPURegs>;
  def CMPLTUri  : SetCCI<"cmpltu", setult, CPURegs>;
  def CMPNEri   : SetCCI<"cmpne ", setne, CPURegs>;  

}

// Branch Patterns
multiclass BranchPats<Instruction BrOp, Instruction CmpOpR, Instruction CmpOpI, 
                      PatFrag cond> {
  def : Pat<(brcond (i32 (cond CPURegs:$lhs, CPURegs:$rhs)), bb:$dst),
            (BrOp (CmpOpR CPURegs:$lhs, CPURegs:$rhs), bb:$dst)>;
  def : Pat<(brcond (i32 (cond CPURegs:$lhs, imm:$rhs)), bb:$dst),
            (BrOp (CmpOpI CPURegs:$lhs, imm:$rhs), bb:$dst)>;
  def : Pat<(brcond (i32 (cond CPURegs:$lhs, 0)), bb:$dst),
            (BrOp (CmpOpR CPURegs:$lhs, R0), bb:$dst)>;
}

defm : BranchPats<BR, CMPEQ,   CMPEQi,   seteq>;
defm : BranchPats<BR, CMPNE,   CMPNEi,   setne>;
defm : BranchPats<BR, CMPLT,   CMPLTi,   setlt>;
defm : BranchPats<BR, CMPLTU,  CMPLTUi,  setult>;
defm : BranchPats<BR, CMPLE,   CMPLEi,   setle>;
defm : BranchPats<BR, CMPLEU,  CMPLEUi,  setule>;
defm : BranchPats<BR, CMPGT,   CMPGTi,   setgt>;
defm : BranchPats<BR, CMPGTU,  CMPGTUi,  setugt>;
defm : BranchPats<BR, CMPGE,   CMPGEi,   setge>;
defm : BranchPats<BR, CMPGEU,  CMPGEUi,  setuge>;

defm : BranchPats<BRF, CMPEQ,   CMPEQi,   setne>;
defm : BranchPats<BRF, CMPNE,   CMPNEi,   seteq>;
defm : BranchPats<BRF, CMPLT,   CMPLTi,   setge>;
defm : BranchPats<BRF, CMPLTU,  CMPLTUi,  setuge>;
defm : BranchPats<BRF, CMPLE,   CMPLEi,   setgt>;
defm : BranchPats<BRF, CMPLEU,  CMPLEUi,  setugt>;
defm : BranchPats<BRF, CMPGT,   CMPGTi,   setle>;
defm : BranchPats<BRF, CMPGTU,  CMPGTUi,  setule>;
defm : BranchPats<BRF, CMPGE,   CMPGEi,   setlt>;
defm : BranchPats<BRF, CMPGEU,  CMPGEUi,  setult>;

defm : BranchPats<BR, CMPEQr,   CMPEQri,   seteq>;
defm : BranchPats<BR, CMPNEr,   CMPNEri,   setne>;
defm : BranchPats<BR, CMPLTr,   CMPLTri,   setlt>;
defm : BranchPats<BR, CMPLTUr,  CMPLTUri,  setult>;
defm : BranchPats<BR, CMPLEr,   CMPLEri,   setle>;
defm : BranchPats<BR, CMPLEUr,  CMPLEUri,  setule>;
defm : BranchPats<BR, CMPGTr,   CMPGTri,   setgt>;
defm : BranchPats<BR, CMPGTUr,  CMPGTUri,  setugt>;
defm : BranchPats<BR, CMPGEr,   CMPGEri,   setge>;
defm : BranchPats<BR, CMPGEUr,  CMPGEUri,  setuge>;

defm : BranchPats<BRF, CMPEQr,   CMPEQri,   setne>;
defm : BranchPats<BRF, CMPNEr,   CMPNEri,   seteq>;
defm : BranchPats<BRF, CMPLTr,   CMPLTri,   setge>;
defm : BranchPats<BRF, CMPLTUr,  CMPLTUri,  setuge>;
defm : BranchPats<BRF, CMPLEr,   CMPLEri,   setgt>;
defm : BranchPats<BRF, CMPLEUr,  CMPLEUri,  setugt>;
defm : BranchPats<BRF, CMPGTr,   CMPGTri,   setle>;
defm : BranchPats<BRF, CMPGTUr,  CMPGTUri,  setule>;
defm : BranchPats<BRF, CMPGEr,   CMPGEri,   setlt>;
defm : BranchPats<BRF, CMPGEUr,  CMPGEUri,  setult>;




multiclass ExtendCmpPats<Instruction CmpOpR, Instruction CmpOpI, CondCode CC> {
  def : Pat<(anyext (setcc CPURegs:$lhs, CPURegs:$rhs, CC)),
            (CmpOpR CPURegs:$lhs, CPURegs:$rhs)>; 
  def : Pat<(zext (setcc CPURegs:$lhs, CPURegs:$rhs, CC)),
            (CmpOpR CPURegs:$lhs, CPURegs:$rhs)>; 
  def : Pat<(sext (setcc CPURegs:$lhs, CPURegs:$rhs, CC)),
            (CmpOpR CPURegs:$lhs, CPURegs:$rhs)>; 
  def : Pat<(anyext (setcc CPURegs:$lhs, imm:$rhs, CC)),
            (CmpOpI CPURegs:$lhs, imm:$rhs)>;
  def : Pat<(zext (setcc CPURegs:$lhs, imm:$rhs, CC)),
            (CmpOpI CPURegs:$lhs, imm:$rhs)>;
  def : Pat<(sext (setcc CPURegs:$lhs, imm:$rhs, CC)),
            (CmpOpI CPURegs:$lhs, imm:$rhs)>;
  // Peepholes
  def : Pat<(anyext (setcc CPURegs:$lhs, 0, CC)),
            (CmpOpR CPURegs:$lhs, 0)>;
  def : Pat<(zext (setcc CPURegs:$lhs, 0, CC)),
            (CmpOpR CPURegs:$lhs, 0)>;
  def : Pat<(sext (setcc CPURegs:$lhs, 0, CC)),
            (CmpOpR CPURegs:$lhs, 0)>;

}

multiclass CmpPats<Instruction CmpOpR, Instruction CmpOpI, CondCode CC> {
  // Peepholes
  def : Pat<(setcc CPURegs:$lhs, 0, CC),
            (CmpOpR CPURegs:$lhs, R0)>;

  def : Pat<(setcc CPURegs:$lhs, CPURegs:$rhs, CC),
            (CmpOpR CPURegs:$lhs, CPURegs:$rhs)>;
  def : Pat<(setcc CPURegs:$lhs, imm:$rhs, CC),
            (CmpOpI CPURegs:$lhs, imm:$rhs)>;

}


defm : CmpPats<CMPEQ,   CMPEQi,   SETEQ>;
defm : CmpPats<CMPNE,   CMPNEi,   SETNE>;
defm : CmpPats<CMPLT,   CMPLTi,   SETLT>;
defm : CmpPats<CMPLTU,  CMPLTUi,  SETULT>;
defm : CmpPats<CMPLE,   CMPLEi,   SETLE>;
defm : CmpPats<CMPLEU,  CMPLEUi,  SETULE>;
defm : CmpPats<CMPGT,   CMPGTi,   SETGT>;
defm : CmpPats<CMPGTU,  CMPGTUi,  SETUGT>;
defm : CmpPats<CMPGE,   CMPGEi,   SETGE>;
defm : CmpPats<CMPGEU,  CMPGEUi,  SETUGE>;




                 
