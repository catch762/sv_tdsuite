//**************************************************
// SUP, or Svvvvyungbepis's Uniform Protocol library
//**************************************************

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

//C++ QtouchApp looks for these tags, there has to be exactly one such section
//containing all variables (of native types like vec4 and of types you declared with macros below)
#define SUP_VARS_BEGIN 
#define SUP_VARS_END


//*************************************************
// This will be moved to sv_preprocessor.glsl later
//*************************************************
#ifndef SV_PREPROCESSOR_SECTION

#define SV_EVAL(x) x

//This exists because if you call SOME_MACRO(2+1), you wont get 3. You will get '2+1'.
//Which would be fine, but you cant use it as part of variable name, for instance.
//This problem is fixed with macro substitutions, enjoy this brilliant solution:

#define SV_PLUS_ONE_0 1
#define SV_PLUS_ONE_1 2
#define SV_PLUS_ONE_2 3
#define SV_PLUS_ONE_3 4
#define SV_PLUS_ONE_4 5
#define SV_PLUS_ONE_5 6
#define SV_PLUS_ONE_6 7
#define SV_PLUS_ONE_7 8
#define SV_PLUS_ONE_8 9
#define SV_PLUS_ONE_9 10
#define SV_PLUS_ONE_10 11
#define SV_PLUS_ONE_11 12
#define SV_PLUS_ONE_12 13
#define SV_PLUS_ONE_13 14
#define SV_PLUS_ONE_14 15
#define SV_PLUS_ONE_15 16

#define SV_MINUS_ONE_0 -1
#define SV_MINUS_ONE_1 0
#define SV_MINUS_ONE_2 1
#define SV_MINUS_ONE_3 2
#define SV_MINUS_ONE_4 3
#define SV_MINUS_ONE_5 4
#define SV_MINUS_ONE_6 5
#define SV_MINUS_ONE_7 6
#define SV_MINUS_ONE_8 7
#define SV_MINUS_ONE_9 8
#define SV_MINUS_ONE_10 9
#define SV_MINUS_ONE_11 10
#define SV_MINUS_ONE_12 11
#define SV_MINUS_ONE_13 12
#define SV_MINUS_ONE_14 13
#define SV_MINUS_ONE_15 14

#define SV_CAT_INNER(a, b) a ## b
#define SV_CAT(a, b) SV_CAT_INNER(a, b)

#define SV_GET_PLUS_ONE(NUMBER) SV_CAT(SV_PLUS_ONE_, NUMBER)
#define SV_GET_MINUS_ONE(NUMBER) SV_CAT(SV_MINUS_ONE_, NUMBER)

#endif



#ifndef SUP_SECTION_MACRO_OPERATIONS_ON_STRUCT_AND_ITS_MEMBERS
//*************************************************************************
// So, there is a struct, and we do various things with it.
// As you can see below, all operations are defined by providing 3 macros:
//
// BEG_yourOperation(...) -- called once in beginning
// MEM_yourOperation(...) -- called for each member variable of the struct
// END_yourOperation(...) -- called once in the end
// 
// Then, you could say: i want 'yourOperation' done on struct type 'Kek'
// and it would work.
//
// See cases below. Lowercase args stand for unused.
//
//*************************************************************************


//Simple standard declaration of structs and its members.
#define BEG_DECLSTRUCT(STRTYPE, strname, strdataidx)	\
	struct STRTYPE {
#define MEM_DECLSTRUCT(strtype, MEMBERTYPE, MEMBERNAME, strname, memberidx, strdataidx)	\
		MEMBERTYPE MEMBERNAME;
#define END_DECLSTRUCT(strtype, size)	\
	};

	


//*********************************************************************************
// We save all default native types size, then each struct containing them 
// can calculate and save its own size, then next struct can include this struct as
// member variable (because it can calculate its size now), and so on.
//*********************************************************************************

//evaluates to variable name containing:
//	size which is number of vec4 entries in that 'uniform vec4 sup_data[];' above
#define TYPESIZE_VARNAME(STRTYPE) STRTYPE ## _structsize

//all native types fit in single vec4 entry
#define SAVE_NATIVE_TYPE_SIZE(NATIVETYPE) const int TYPESIZE_VARNAME(NATIVETYPE) = 1;

//bool not supported here or anywhere.
SAVE_NATIVE_TYPE_SIZE(float)
SAVE_NATIVE_TYPE_SIZE(vec2)
SAVE_NATIVE_TYPE_SIZE(vec3)
SAVE_NATIVE_TYPE_SIZE(vec4)
SAVE_NATIVE_TYPE_SIZE(int)
SAVE_NATIVE_TYPE_SIZE(ivec2)
SAVE_NATIVE_TYPE_SIZE(ivec3)
SAVE_NATIVE_TYPE_SIZE(ivec4)

#define BEG_SAVETYPESIZE(STRTYPE, strname, strdataidx)	\
	const int TYPESIZE_VARNAME(STRTYPE) =
#define MEM_SAVETYPESIZE(strtype, MEMBERTYPE, membername, strname, memberidx, strdataidx)	\
	TYPESIZE_VARNAME(MEMBERTYPE) +
#define END_SAVETYPESIZE(strtype, size)	\
	0;


//evaluates to variable name containing:
//	offset (in number of vec4 entries) from start of the struct for this member 
#define MEMBEROFFSET_VARNAME_IMP(STRTYPE, MEMBERIDX) STRTYPE ## _offset_for_memberidx_ ## MEMBERIDX
#define MEMBEROFFSET_VARNAME_INT(STRTYPE, MEMBERIDX) MEMBEROFFSET_VARNAME_IMP(STRTYPE, MEMBERIDX)
#define MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX) MEMBEROFFSET_VARNAME_INT(STRTYPE, SV_EVAL(MEMBERIDX))


//We save offset 0 for memberidx = 0 to variable
#define BEG_SAVEFIRSTMEMBEROFFSET(STRTYPE, strname, strdataidx)	\
	const int MEMBEROFFSET_VARNAME_FIN(STRTYPE, 0) = 0;
#define MEM_SAVEFIRSTMEMBEROFFSET(strtype, membertype, membername, strname, memberidx, strdataidx)
#define END_SAVEFIRSTMEMBEROFFSET(strtype, size)


//Then, for each memberidx we save offset for memberidx+1 (yes, we ll end up with one extra variable in the end, but we dont care)
#define BEG_SAVENEXTMEMBEROFFSETS(strtype, strname, strdataidx)
#define MEM_SAVENEXTMEMBEROFFSETS(STRTYPE, MEMBERTYPE, membername, strname, MEMBERIDX, strdataidx)	\
			const int MEMBEROFFSET_VARNAME_FIN(STRTYPE, SV_GET_PLUS_ONE(MEMBERIDX)) = 			\
				MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX) + TYPESIZE_VARNAME(MEMBERTYPE);
#define END_SAVENEXTMEMBEROFFSETS(strtype, size)












#endif



#define SUP_DATA_FINAL_INDEX(VARIDX, STRTYPE, MEMBERIDX) (VARSUPDATAIDX_VARNAME_FIN(VARIDX) + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX))


#ifdef _spaceindented_python_code_which_generates_section_below
/*
exec("""
argcfrom = 1
argcto = 4

levelfrom = 0
levelto = 2

defline_begin_a = "#define STRMAIN_ARG"
defline_begin_b = "(T, V, N, I, L, "

begline = "BEG_ ## V(T, N, I) "

for level in range(levelfrom, levelto+1):
    for argc in range(argcfrom, argcto+1):
        endline = f"END_ ## V(T, {argc})\n"
    
        defline_mid = ""
        for i in range(0, argc):
            defline_mid += f"T{i}, N{i}"
            if i != argc-1:
                defline_mid += ", "
            else:
                defline_mid += ") "

        defline = f"#define STRMAIN_ARG{argc}_L{level}(T, V, N, I, " + defline_mid
        
        memline = ""
        for i in range(0, argc):
            memvar = f"MEM_ ## V(T, T{i}, N{i}, N, {i}, I) "
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
#define STRMAIN_ARG1_L0(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define STRMAIN_ARG2_L0(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define STRMAIN_ARG3_L0(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define STRMAIN_ARG4_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define STRMAIN_ARG1_L1(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define STRMAIN_ARG2_L1(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define STRMAIN_ARG3_L1(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define STRMAIN_ARG4_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define STRMAIN_ARG1_L2(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define STRMAIN_ARG2_L2(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define STRMAIN_ARG3_L2(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define STRMAIN_ARG4_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)



//******************AUTOGENERATED WITH PYTHON*************************
#endif



//i dont fully understand why this works and makes macro expand properly, but i need this retardation
#define VARSUPDATAIDX_VARNAME_IMP(VARIDX) sup_data_index_for_varidx_ ## VARIDX
#define VARSUPDATAIDX_VARNAME_INT(VARIDX) VARSUPDATAIDX_VARNAME_IMP(VARIDX)
#define VARSUPDATAIDX_VARNAME_FIN(VARIDX) VARSUPDATAIDX_VARNAME_INT(SV_EVAL(VARIDX))

//we just save initial here
const int VARSUPDATAIDX_VARNAME_FIN(0) = 0;


#define SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(THISVARIDX, THISVARIDXTYPE) \
			const int VARSUPDATAIDX_VARNAME_FIN(SV_GET_PLUS_ONE(THISVARIDX)) = \
				VARSUPDATAIDX_VARNAME_FIN(THISVARIDX) + TYPESIZE_VARNAME(THISVARIDXTYPE);



#define GETMETA(STRTYPE) 		STRMETA_ ## STRTYPE



#define ui(data_for_cpp_to_parse) 
#define STRDECL(STRTYPE) 		GETMETA(STRTYPE)(DECLSTRUCT, ~, ~, 0)				\
								GETMETA(STRTYPE)(SAVETYPESIZE, ~, ~, 0)			\
								GETMETA(STRTYPE)(SAVEFIRSTMEMBEROFFSET, ~, ~, 0)	\
								GETMETA(STRTYPE)(SAVENEXTMEMBEROFFSETS, ~, ~, 0)
								


#ifdef expected___

//Data:
struct Inner
{
	vec4 aaa;
	vec4 bbb;
};
struct Outer
{
	Inner a;
	float simple;
}
Outer out;

Inner getVarAtSupDataIndex_Inner(int supDataIndex) 
{ 
Inner res; 
res.aaa = getVarAtSupDataIndex_vec4(supDataIndex + Inner_offset_for_memberidx_0); 
res.bbb = getVarAtSupDataIndex_float(supDataIndex + Inner_offset_for_memberidx_1); 
return res; 
} 

Outer getVarAtSupDataIndex_Outer(int supDataIndex) 
{ 
Outer res; 
res.inst = getVarAtSupDataIndex_Inner(supDataIndex + Outer_offset_for_memberidx_0); 
res.simple = getVarAtSupDataIndex_float(supDataIndex + Outer_offset_for_memberidx_1); 
return res; 
}

//all of the above is created as expected

//!!! This is getter functions i need to be created automatically
Outer out();
Inner out_a();
vec4 	out_a_aaa();
vec4 	out_a_bbb();
float out_simple();





#endif





#ifndef _ALT_VAR_DECL_

//Func argument: (int supDataIndex)
#define GETVARATINDEX_FUNCNAME(TYPENAME) getVarAtSupDataIndex_ ## TYPENAME




#define BEG_MAKEGETVARATINDEXFUNC(STRTYPE, STRNAME, strdataidx)	\
	STRTYPE GETVARATINDEX_FUNCNAME(STRTYPE) (int supDataIndex) 	\
	{															\
		STRTYPE res;
		
#define MEM_MAKEGETVARATINDEXFUNC(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, strdataidx)	\
		res.MEMBERNAME = GETVARATINDEX_FUNCNAME(MEMBERTYPE)( 										\
							supDataIndex + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX) 			\
						);
		
#define END_MAKEGETVARATINDEXFUNC(strtype, size)	\
		return res;									\
	}







#define STRMAIN(ARGCOUNT, LEVEL) STRMAIN_ARG ## ARGCOUNT ## _L ## LEVEL 









#define STRMETA_Inner(V,N,I,L) STRMAIN(2,L)(Inner,V,N,I,\
vec4, 	aaa,	\
float, 	bbb)
STRDECL(Inner)

#define STRMETA_Outer(V,N,I,L) STRMAIN(2,L)(Outer,V,N,I,\
Inner, 	a,				\
float, 	simple)
STRDECL(Outer)

//Unfortunately we have to.
#define SUP_CUSTOMTYPESLIST(F) \
	F(Inner)\
	F(Outer)

#define SUP_VARLIST(F) \
	F(0, Outer, outx)

//just to convey meaning better
#define FOR_EACH_VARLIST_ENTRY(FUNCVISITOR) SUP_VARLIST(FUNCVISITOR)
#define FOR_EACH_CUSTOMTYPE(FUNCVISITOR) SUP_CUSTOMTYPESLIST(FUNCVISITOR)

#define PLUS_SIZE_OF_VARLIST_ENTRY(varidx, STRTYPE, strname) + TYPESIZE_VARNAME(STRTYPE)


const int entireVarlistSize = FOR_EACH_VARLIST_ENTRY(PLUS_SIZE_OF_VARLIST_ENTRY);

//everything goes through this
uniform vec4 sup_data[entireVarlistSize];

#ifndef GETVARATINDEX_for_native

#define FOR_EACH_SUPPORTED_NATIVE_TYPE(F) \
	F(float)\
	F(vec2)\
	F(vec3)\
	F(vec4)\
	F(int)\
	F(ivec2)\
	F(ivec3)\
	F(ivec4)

#define MAKE_GETVARATINDEX_FUNC_FOR_NATIVE_TYPE(TYPE) 	\
	TYPE GETVARATINDEX_FUNCNAME(TYPE) (int supDataIndex)\
	{													\
		return sup_as_ ## TYPE (sup_data[supDataIndex]);\
	}

FOR_EACH_SUPPORTED_NATIVE_TYPE(MAKE_GETVARATINDEX_FUNC_FOR_NATIVE_TYPE)

#endif
			
#define MAKE_GETVARATINDEX_FUNC_FOR_CUSTOM_TYPE(STRTYPE) 	\
	GETMETA(STRTYPE)(MAKEGETVARATINDEXFUNC, ~, ~, 0)

FOR_EACH_CUSTOMTYPE(MAKE_GETVARATINDEX_FUNC_FOR_CUSTOM_TYPE)




//Experimental:

//This is needed for MAKEGETTERS macros (meaning of this, when we hit a native
//type, we do nothing and dont try to look at its members)
#define STRMETA_float(V,N,I,L)
#define STRMETA_vec2(V,N,I,L)
#define STRMETA_vec3(V,N,I,L)
#define STRMETA_vec4(V,N,I,L)
#define STRMETA_int(V,N,I,L)
#define STRMETA_ivec2(V,N,I,L)
#define STRMETA_ivec3(V,N,I,L)
#define STRMETA_ivec4(V,N,I,L)

#define CATNAMEPATH_INNER(NAMEPATH, MEMBERNAME) NAMEPATH ## _ ## MEMBERNAME
#define CATNAMEPATH(NAMEPATH, MEMBERNAME) CATNAMEPATH_INNER(NAMEPATH, MEMBERNAME)

#define MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX) 		\
	STRTYPE STRNAME()										\
	{														\
		return GETVARATINDEX_FUNCNAME(STRTYPE) (STRDATAIDX);\
	}

#define BEG_MAKEGETTERS_L0(STRTYPE, STRNAME, STRDATAIDX) \
			MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS_L0(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
			GETMETA(MEMBERTYPE)( MAKEGETTERS_L1, 											\
								 CATNAMEPATH(STRNAME, MEMBERNAME), 							\
								 STRDATAIDX + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX),	\
								 1 )
#define END_MAKEGETTERS_L0(strtype, size)

#define BEG_MAKEGETTERS_L1(STRTYPE, STRNAME, STRDATAIDX) \
			MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS_L1(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
			GETMETA(MEMBERTYPE)( MAKEGETTERS_L2, 											\
								 CATNAMEPATH(STRNAME, MEMBERNAME), 							\
								 STRDATAIDX + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX),	\
								 2 )
#define END_MAKEGETTERS_L1(strtype, size)

#define BEG_MAKEGETTERS_L2(STRTYPE, STRNAME, STRDATAIDX) \
			MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS_L2(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
			GETMETA(MEMBERTYPE)( MAKEGETTERS_L3, 											\
								 CATNAMEPATH(STRNAME, MEMBERNAME), 							\
								 STRDATAIDX + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX),	\
								 3 )
#define END_MAKEGETTERS_L2(strtype, size)



#define BEG_MAKEGETTERS(STRTYPE, STRNAME, STRDATAIDX) \
		BEG_MAKEGETTERS_L0(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
		MEM_MAKEGETTERS_L0(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX)
#define END_MAKEGETTERS(strtype, size)	\
		END_MAKEGETTERS_L0(strtype, size)



//-------->Conclusion: STRMAIN_ARG2 cant expand second time, so you need STRMAIN_ARG2_L0 and so on, as well ^^






// /Experimental^




#define INIT_VARLIST_ENTRY(VARIDX, STRTYPE, STRNAME) 				\
			SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(VARIDX, STRTYPE)		\
			GETMETA(STRTYPE)(MAKEGETTERS, STRNAME, VARSUPDATAIDX_VARNAME_FIN(VARIDX), 0)
			
//MAKE_GETTER_FUNC(STRTYPE, STRNAME, VARSUPDATAIDX_VARNAME_FIN(VARIDX))			

FOR_EACH_VARLIST_ENTRY(INIT_VARLIST_ENTRY)

vec4 ok = outx_a_aaa();



#endif












//i stopped at: its better but MEM_MAKEGETTERS_L1 not evaled, this can be fixed