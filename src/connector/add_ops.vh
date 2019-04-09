`define ADD_MOD(a,b,len) (((a)+(b)<(len))?((a)+(b)):((a)+(b)-(len)))
`define SUB_MOD(a,b,len) (((a)<(b))?((len)-(b)+(a)):((a)-(b)))