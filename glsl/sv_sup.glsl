//**************************************************
// SUP, or Svvvvyungbepis's Uniform Protocol library
//**************************************************

//everything goes through this
uniform vec4 sup_data[];

float 	sup_as_float	(vec4 v) {return v.x;	}
vec2 	sup_as_vec2		(vec4 v) {return v.xy;	}
vec3 	sup_as_vec3		(vec4 v) {return v.xyz;	}
vec4 	sup_as_vec4		(vec4 v) {return v;		}
int 	sup_as_int		(vec4 v) {return int(v.x + 0.5);			}
ivec2 	sup_as_ivec2	(vec4 v) {return ivec2(v.xy + vec2(0.5));	}
ivec3 	sup_as_ivec3	(vec4 v) {return ivec3(v.xyz + vec3(0.5));	}
ivec4 	sup_as_ivec4	(vec4 v) {return ivec4(v + vec4(0.5));		}

//ADDTODICT section is declared entirely in /* comments */, so dont need defines, but anyways.
//This section contains pseudo-python-looking code defining simple variables which can later be referenced
//in ui("..."); this is parsed in C++ by QtouchApp 
#define SUP_ADDTODICT_BEGIN
#define SUP_ADDTODICT_END

//Todo remove, its unused. C++ dont look for it. Dont need to define these sections, put decls anywhere
#define SUP_STRUCTS_BEGIN
#define SUP_STRUCTS_END

//C++ QtouchApp looks for these tags, there has to be exactly one such section
//containing all variables (of native types like vec4 and of types you declared with macros below)
#define SUP_VARS_BEGIN 
#define SUP_VARS_END

#define INDR(P) P

//*************************************************************************
// So, there is a struct, and we do various things with it.
// As you can see below, all operations are defined by providing 3 macros:
//
// BEG_yourOperation(...) -- called once in beginning
// MEM_yourOperation(...) -- called for each member variable of the struct
// END_yourOperation(...) -- called once in the end
// 
// Then, you could say "i want 'yourOperation' done on struct type 'Kek'
// and it would work.
//*************************************************************************

//Simple standard declaration of structs and its members.
//Lowercase args here and everywhere stand for unused
#define BEG_DECLSTRUCT(STRTYPE, strname) 										struct STRTYPE {
#define MEM_DECLSTRUCT(strtype, MEMBERTYPE, MEMBERNAME, strname, memberidx)			MEMBERTYPE MEMBERNAME;
#define END_DECLSTRUCT(strtype, size)											};

//Defines getter func for instance of some struct;
//member variables are copied into instance
	//here STRNAME is STRPATH
#define BEG_MAKESTRUCTINSTGETTER(STRTYPE, STRNAME) 										STRTYPE STRNAME(){STRTYPE res;
#define MEM_MAKESTRUCTINSTGETTER(STRTYPE, membertype, MEMBERNAME, STRNAME, memberidx)		res.MEMBERNAME = STRNAME ## _ ## MEMBERNAME();
#define END_MAKESTRUCTINSTGETTER(strtype, size)											return res;}










//i stopped at: adding varidx and getting final idx here;
//and also actually doing nested str path, makin STRNAME a path,, etc/













//Defines getter func for each individual member variable
	//here STRNAME is STRPATH
	//issue with index!
#define BEG_MAKEMEMBERGETTERS(strtype, strname)
#define MEM_MAKEMEMBERGETTERS(strtype, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX)	MEMBERTYPE STRNAME ## _ ## MEMBERNAME()\
																					{ return sup_as_ ## MEMBERTYPE(sup_data[__LINE__ + IDX - 1]); }
#define END_MAKEMEMBERGETTERS(strtype, size)

//Simply gets count of member variables.
#define BEG_RETURNSSIZE(u, u2)
#define MEM_RETURNSSIZE(u, u2, u3, u4)
#define END_RETURNSSIZE(u, THESIZE) THESIZE

//*********************************************************************************
// We save all default native types size, then each struct containing them 
// can calculate and save its own size, then next struct can include this struct as
// member variable (because it can calculate its size now), and so on.
//*********************************************************************************

//evaluates to variable name containing:
//	number of vec4 entries in that 'uniform vec4 sup_data[];' above
#define TYPESIZE_VARNAME(STRTYPE) STRTYPE ## _structsize

#define BEG_SAVETYPESIZE(STRTYPE, u2)				const int TYPESIZE_VARNAME(STRTYPE) =
#define MEM_SAVETYPESIZE(MEMBERTYPE, u2, u3, u4)		TYPESIZE_VARNAME(MEMBERTYPE) +
#define END_SAVETYPESIZE(u, THESIZE) THESIZE		0;


//evaluates to variable name containing:
//	offset (in number of vec4 entries) from start of the struct for this member 
#define MEMBEROFFSET_VARNAME(STRTYPE, MEMBERIDX) STRTYPE ## _offset_for_memberidx_ ## MEMBERIDX

//We save offset 0 for memberidx = 0 to variable
#define BEG_SAVEFIRSTMEMBEROFFSET(STRTYPE, u2) 			const int MEMBEROFFSET_VARNAME(STRTYPE, 0) = 0;
#define MEM_SAVEFIRSTMEMBEROFFSET(u, u2, u3, u4, u5)
#define END_SAVEFIRSTMEMBEROFFSET(u, u2)


//Then, for each memberidx we save offset for memberidx+1 (yes, we ll end up with one extra variable in the end, but we dont care)
#define BEG_SAVENEXTMEMBEROFFSETS(u, u2)
#define MEM_SAVENEXTMEMBEROFFSETS(STRTYPE, MEMBERTYPE, u2, u3, MEMBERIDX)		const int MEMBEROFFSET_VARNAME(STRTYPE, MEMBERIDX+1) = \
																					MEMBEROFFSET_VARNAME(STRTYPE, MEMBERIDX) + TYPESIZE_VARNAME(MEMBERTYPE);
#define END_SAVENEXTMEMBEROFFSETS(u, u2)






#ifdef _spaceindented_python_code_which_generates_section_below
/*
exec("""
argcfrom = 1
argcto = 16

defline_begin_a = "#define STRMAIN_ARG"
defline_begin_b = "(T, V, N, "

begline = "BEG_ ## V(T, N) "

for argc in range(argcfrom, argcto+1):
    endline = f"END_ ## V(T, {argc})\\n"

    defline_mid = ""
    for i in range(0, argc):
        defline_mid += f"T{i}, N{i}"
        if i != argc-1:
            defline_mid += ", "
        else:
            defline_mid += ") "
    defline = defline_begin_a + str(argc) + defline_begin_b + defline_mid

    memline = ""
    for i in range(0, argc):
        memvar = f"MEM_ ## V(T, T{i}, N{i}, N, {i}) "
        memline += memvar + " "

    finalstr = defline + begline + memline + endline
    print(finalstr)
""")
*/
#endif

#ifndef _strmains_autogen_section_
//T: type of struct, V: macro version for pattern matching ('yourOperation' from example above),
//N: name of struct, T0/N0 ...: are type/name pairs for struct members
//******************AUTOGENERATED WITH PYTHON*************************
#define STRMAIN_ARG1(T, V, N, T0, N0) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  END_ ## V(T, 1)

#define STRMAIN_ARG2(T, V, N, T0, N0, T1, N1) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  END_ ## V(T, 2)

#define STRMAIN_ARG3(T, V, N, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  END_ ## V(T, 3)

#define STRMAIN_ARG4(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  END_ ## V(T, 4)

#define STRMAIN_ARG5(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  END_ ## V(T, 5)

#define STRMAIN_ARG6(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  END_ ## V(T, 6)

#define STRMAIN_ARG7(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  END_ ## V(T, 7)

#define STRMAIN_ARG8(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  END_ ## V(T, 8)

#define STRMAIN_ARG9(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  END_ ## V(T, 9)

#define STRMAIN_ARG10(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  END_ ## V(T, 10)

#define STRMAIN_ARG11(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  END_ ## V(T, 11)

#define STRMAIN_ARG12(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  MEM_ ## V(T, T11, N11, N, 11)  END_ ## V(T, 12)

#define STRMAIN_ARG13(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  MEM_ ## V(T, T11, N11, N, 11)  MEM_ ## V(T, T12, N12, N, 12)  END_ ## V(T, 13)

#define STRMAIN_ARG14(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  MEM_ ## V(T, T11, N11, N, 11)  MEM_ ## V(T, T12, N12, N, 12)  MEM_ ## V(T, T13, N13, N, 13)  END_ ## V(T, 14)

#define STRMAIN_ARG15(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  MEM_ ## V(T, T11, N11, N, 11)  MEM_ ## V(T, T12, N12, N, 12)  MEM_ ## V(T, T13, N13, N, 13)  MEM_ ## V(T, T14, N14, N, 14)  END_ ## V(T, 15)

#define STRMAIN_ARG16(T, V, N, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N) MEM_ ## V(T, T0, N0, N, 0)  MEM_ ## V(T, T1, N1, N, 1)  MEM_ ## V(T, T2, N2, N, 2)  MEM_ ## V(T, T3, N3, N, 3)  MEM_ ## V(T, T4, N4, N, 4)  MEM_ ## V(T, T5, N5, N, 5)  MEM_ ## V(T, T6, N6, N, 6)  MEM_ ## V(T, T7, N7, N, 7)  MEM_ ## V(T, T8, N8, N, 8)  MEM_ ## V(T, T9, N9, N, 9)  MEM_ ## V(T, T10, N10, N, 10)  MEM_ ## V(T, T11, N11, N, 11)  MEM_ ## V(T, T12, N12, N, 12)  MEM_ ## V(T, T13, N13, N, 13)  MEM_ ## V(T, T14, N14, N, 14)  MEM_ ## V(T, T15, N15, N, 15)  END_ ## V(T, 16)


//******************AUTOGENERATED WITH PYTHON*************************
#endif



/*
------------------------------------------------------------------------------------------
I ll put usage example beforehand:
 
Thats how you declare all your structs, by providing define like this:
STRMETA_yourStructName which calls STRMAIN_ARG[N] where [N] is number of member variables.
Once again, (V, N) args are:
		V: version of macro operation, e.g. 'yourOperation' from example above
 		N: name of instance of this struct
------------------------------------------------------------------------------------------

#define STRMETA_Kek(V,N) STRMAIN_ARG2(Kek,V,N,\
vec4, 	a, 	ui("color = myred")\
int, 	b)	ui("rad='ry an go sling'")	
STRDECL(Kek)

//no empty lines in this section at all, logic is tied to __LINE__
#line 	0
SUP_VARS_BEGIN
		STR(Kek, first) 	ui("C2")
#line	ooo(Kek)
		STR(Kek, second) 	ui("C2")
#line	ooo(Kek)
SUP_VARS_END 
*/

//takes index of variable in final var list inside SUP_VARS_BEGIN ... SUP_VARS_BEGIN section
//evaluates to variable name containing:
//	index in sup_data where this variable (native or struct) begins
#define VARSUPDATAIDX_VARNAME(VARIDX) sup_data_index_for_varidx_ ## VARIDX

//we just save initial here
const int VARSUPDATAIDX_VARNAME(0) = 0;

#define SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(THISVARIDX, THISVARIDXTYPE) \
			const int VARSUPDATAIDX_VARNAME(THISVARIDX+1) = \
				VARSUPDATAIDX_VARNAME(THISVARIDX) + TYPESIZE_VARNAME(THISVARIDXTYPE);



#define GETMETA(STRTYPE) 		STRMETA_ ## STRTYPE

//These are the only macros you should use:
//and you have to define STRMETA_yourstructtype(V,N) macro urself

//C++ QTouchApp defines what can be contained in these ui("...") sections.
//Its subject to change, im not even gonna describe current version.
#define ui(data_for_cpp_to_parse) 
#define STRDECL(STRTYPE) 		GETMETA(STRTYPE)(DECLSTRUCT, u)\
								GETMETA(STRTYPE)(SAVETYPESIZE, u)
#define VAR(T, N) 				T N(){ return sup_as_ ## T(sup_data[__LINE__ - 1]); }


//#define STR(STRTYPE, STRNAME) 	GETMETA(STRTYPE)(MAKEMEMBERGETTERS, STRNAME) GETMETA(STRTYPE)(MAKESTRUCTINSTGETTER, STRNAME)


//This expression with __LINE__ makes sure our first STR call gets VARIDX=0, next 1 and so on.
#define STR(STRTYPE, STRNAME) 											\
			SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(__LINE__ - 1, STRTYPE) 	\
			GETMETA(STRTYPE)(SAVEFIRSTMEMBEROFFSET, STRNAME) 			\
			GETMETA(STRTYPE)(SAVENEXTMEMBEROFFSETS, STRNAME) 			\
			GETMETA(STRTYPE)(MAKEMEMBERGETTERS, 	STRNAME) 			\
			GETMETA(STRTYPE)(MAKESTRUCTINSTGETTER, 	STRNAME)


//always use ooo after STR (its not needed for VAR cause 
#define ooo(STRTYPE) 			__LINE__ + TYPESIZE_VARNAME(STRTYPE) - 1
//////////////////////////////////////////////////////////////////////////////////////////////



