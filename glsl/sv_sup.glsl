//***************************************************************
// SUP, or Svvvv Uniform Protocol module
// Dependencies: none.
//
// I hope you are reading this in editor, which lets you collapse
// #ifdef sections, or this will be absolutely unreadable.
//***************************************************************

#ifdef EXPLANATION_OF_WHAT_THIS_MODULE_DOES

// Consider you have following shader data:

struct Inner
{
	vec4 aaa;
	vec4 bbb;
}

struct Outer
{
	Inner inn;
	float simpleVar;
}

uniform Outer myStruct;
uniform vec4 nativeVec;

// What if you wanted to set this uniform data externally?
// Well, its easy to do it in any language via uniform locations / uniform buffer objects / whatever.
//
// However, in Touchdesigner shader host, the options are:
//	- Setup every single field by hand via UI (im not doing this)
//	- Declare a single uniform array of floats and map your structs to using
//	  absolutely nightmarish set of preprocessor macros.
//
// So thats what we are gonna do in this module.
//
// We are gonna declare a single uniform array of floats and map our structs to it using 
// absolutely nightmarish set of preprocessor macros.
//
// (And ofcourse, this means that you need to make a tool which actually fills in this array data. My tool for this
// is a C++ Qt app sv_qtouch; but talking about it is mostly irrelevant. All the shader cares about is that
// there is a float array, and that structs are correctly mapped to it.)
//
// That said, i also have to mention: my QTouch app, mentioned above, parses the glsl code which uses this module,
// in order to recreate this data in C++ in order to create UI for this data and fill that array of floats.
// Therefore, a secondary, very minor objective of this sv_sup module, is to make sure our data is declared in a way,
// that when we parse this shader code in our C++ app, we can obtain all the information that interests us.
// This aspect is not really present in how preprocessor logic itself works, it is defined by certain code style/formatting rules.
//
// So, head over to the next section and see how it all works.
#endif

//Im putting this example here, because this reading order makes sense, but obviously, 
//it will only work after all the content of this file is included first
#ifdef EXAMPLE_OF_HOW_THIS_MODULE_IMPLEMENTS_HYPOTHETICAL_EXAMPLE_FROM_SECTION_ABOVE

// SUP_ADDTODICT is entirely optional section. Yes, its in the comments. The comments will be parsed by C++.
// The idea is, later on, you will include some metadata for widgets for data.
// E.g. you declare a float, and you will want to include metadata with the meaning 
// "when UI widget is made for this float, i want its min=10, max=100 and default value=50"
// 
// But what if you want to make some named constant and refer to it in these metadata description?
// This is the section that contains these named constants.
//
// What data exactly and what format is expected here - thats defined by QTouch, and is out of scope
// of this documentation. Data format may change and this example section might be outdated.
// Here I just wanted to explain, what this section is for, roughly.

/*
SUP_ADDTODICT_BEGIN
myLimits = [10, 100, 50]
SUP_ADDTODICT_END
*/

//First, declare the structs:

//[!] this '2' on first line means '2 member variables in the struct'
//[!] keep it same style: one variable per line, no empty lines. This is requirement of QTouch parser, nothing else.
#define TYPEMETA_Inner(V,N,I,L) TYPEMAIN(2,L)(Inner,V,N,I,	\
vec4, 	aaa,												\
vec4,	bbb) 	
SUP_STRDECL(Inner) 

//Note the optional ui("") macro, it expands to nothing, is only parsed by QTouch,
//and is interpreted by widget for that variable on the same line.
#define TYPEMETA_Outer(V,N,I,L) TYPEMAIN(2,L)(Outer,V,N,I,	\
Inner, 	inn,												\
float,	simpleVar) 	ui("lims = myLimits")
SUP_STRDECL(Outer) 

//We have to define macro with this name, and list all struct types that is
//used in varlist, including nested types.
//
//[!] Btw, this form allows you to concatenate lists this way,
//	  e.g. you can add simillar macro TYPES_OF_SOME_SUBMODULE(F) and simply include it here once.
#define SUP_LIST_OF_ALL_STRUCT_TYPES_USED_IN_VARLIST(F) \
	F(Inner)\
	F(Outer)

//This, the varlist, lists all our data. Of native types and of types we declared above.
//
//SUP_VARS_BEGIN, SUP_VARS_END macros dont do anything, they are included just to help QTouch parser
//find the data.
//
// [!] every variable entry must begin with its index, F(0, ...) F(1, ...) F(2, ...) and so on.
//
// Also note how we can have ui("") macros here as well.
#define SUP_VARLIST(F)	\
		SUP_VARS_BEGIN	\
		F(0,  Outer, myStruct)\
		F(1,  vec4, nativeVec) ui("some metadata for UI widget for this variable")\
		SUP_VARS_END

//What this macro does is:
//	- calculates total size of data in SUP_VARLIST
//	- creates the array: uniform vec4 sup_data[SUP_VARLIST_SIZE];
//	- creates function which take offset in that array and return variable
//	  of each type, reading them from that offset. Its called internally, but FYI.
//	- creates functions to access every variable in SUP_VARLIST; see just below
SUP_INITIALIZE_VARLIST

//So, the auto-created functions to access variables from SUP_VARLIST, mapping them to sup_data array:
//Note how this includes all members through underscore, and all members of members, and so on.
Outer copyOf_myStruct 	= myStruct();
Inner member_inn 			= myStruct_inn();
float member_simpleVar 		= myStruct_simpleVar();
vec4  copyOf_nativeVec 	= nativeVec();


#endif

#ifdef SOME_NOTES_ON_IMPLEMENTATION_DETAILS_AND_TROUBLESHOOTING_AND_TODO
/*
	0. Implementation is based on assumption that aggressive inlining will optimize
	away all the functions for accessing struct instances; otherwise im fucked.
	The more specific your access function calls are, the better, anyway. Probably.
	(i mean, dont request large struct to copy one field, just call that field accessor)

	1. Array type
	
	You may have noticed: wait, the array is vec4 sup_data[].
	Why vec4 and not float?
	Well, for simplicity, so every variable fits in vec4.
	Yes, it means if im storing single float, it takes space of four.
	I had enough on my plate at the moment; that is the first thing to improve on TODO list.
	
	2. The need for index
	
	Why do we have to include index in F(*index*, Type, varname)? Could it be made automatically?
	No.
	The reason is: we have to walk through varlist twice.
	First we walk it to obtain size of array.
	Only then we can create array with that size.
	Only then we can walk varlist second time, to create accessors.
	Since we walk two times, we need to define VARLIST as list with a visitor, and it
	doesnt let us count entries using __LINE__.
	The only other alternative i see would be to generate SUP_VARLIST_1, 
	SUP_VARLIST_2 ... SUP_VARLIST500 macros for every possible argcount.
	I went with simpler approach.
	
	3. Limits:
	
		3.1) We can do nested structs, thats the whole idea. But if you want to go, say, 10 levels deep,
		go to TYPEMAIN_AUTOGENERATED sections, call the python script and regenerate macros up to 10th
		depth level. Then go to MAKEGETTERS_MACROS_FOR_DIFFERENT_LEVELS section and add macros up to _L10.
		By default there are 4 levels or something.
				
		3.2) The number of vars in SUP_VARLIST is limited by SUP_PLUS_ONE_ macros in
		SUP_PREPROCESSOR_SECTION; if you need more vars, add more entries there.
		
	4. A lot of internal macros below have large list of arguments for all cases,
	some arguments not necessarily defined for every context macro can be used at.
	But they are still there. ~ is passed to mark unused argument.
	
	5. Some macros have 3 versions which call each other:
		SOMETHING_IMP - implementation
		SOMETHING_INT - intermediate
		SOMETHING_FIN - final, the one you call.
		
	This is a hack needed in some cases where macro wouldnt expand to macro value otherwise.
	Im not entirely sure when exactly this is needed and why this works.
*/
#endif

//A list that defines all supported native types.
//bool not supported here or anywhere.
#define FOR_EACH_SUPPORTED_NATIVE_TYPE(F) \
	F(float)\
	F(vec2)\
	F(vec3)\
	F(vec4)\
	F(int)\
	F(ivec2)\
	F(ivec3)\
	F(ivec4)

//Preprocessor utils
#ifndef SUP_PREPROCESSOR_SECTION

#define SUP_EVAL(x) x

//This exists because if you call SOME_MACRO(2+1), you wont get 3. You will get '2+1'.
//Which would be fine, but you cant use it as part of variable name, for instance.
//This problem is fixed with macro substitutions, enjoy this brilliant solution:

//there are as many (top level) vars in varlist supported, as there are entries here
#define SUP_PLUS_ONE_0 1
#define SUP_PLUS_ONE_1 2
#define SUP_PLUS_ONE_2 3
#define SUP_PLUS_ONE_3 4
#define SUP_PLUS_ONE_4 5
#define SUP_PLUS_ONE_5 6
#define SUP_PLUS_ONE_6 7
#define SUP_PLUS_ONE_7 8
#define SUP_PLUS_ONE_8 9
#define SUP_PLUS_ONE_9 10
#define SUP_PLUS_ONE_10 11
#define SUP_PLUS_ONE_11 12
#define SUP_PLUS_ONE_12 13
#define SUP_PLUS_ONE_13 14
#define SUP_PLUS_ONE_14 15
#define SUP_PLUS_ONE_15 16
#define SUP_PLUS_ONE_16 17
#define SUP_PLUS_ONE_17 18
#define SUP_PLUS_ONE_18 19
#define SUP_PLUS_ONE_19 20
#define SUP_PLUS_ONE_20 21
#define SUP_PLUS_ONE_21 22
#define SUP_PLUS_ONE_22 23
#define SUP_PLUS_ONE_23 24
#define SUP_PLUS_ONE_24 25
#define SUP_PLUS_ONE_25 26
#define SUP_PLUS_ONE_26 27
#define SUP_PLUS_ONE_27 28
#define SUP_PLUS_ONE_28 29
#define SUP_PLUS_ONE_29 30
#define SUP_PLUS_ONE_30 31
#define SUP_PLUS_ONE_31 32
#define SUP_PLUS_ONE_32 33
#define SUP_PLUS_ONE_33 34
#define SUP_PLUS_ONE_34 35
#define SUP_PLUS_ONE_35 36
#define SUP_PLUS_ONE_36 37
#define SUP_PLUS_ONE_37 38
#define SUP_PLUS_ONE_38 39
#define SUP_PLUS_ONE_39 40
#define SUP_PLUS_ONE_40 41
#define SUP_PLUS_ONE_41 42
#define SUP_PLUS_ONE_42 43
#define SUP_PLUS_ONE_43 44
#define SUP_PLUS_ONE_44 45
#define SUP_PLUS_ONE_45 46
#define SUP_PLUS_ONE_46 47
#define SUP_PLUS_ONE_47 48
#define SUP_PLUS_ONE_48 49
#define SUP_PLUS_ONE_49 50

#define SUP_CAT_INNER(a, b) a ## b
#define SUP_CAT(a, b) SUP_CAT_INNER(a, b)

#define SUP_GET_PLUS_ONE(NUMBER) SUP_CAT(SUP_PLUS_ONE_, NUMBER)

#endif

#ifndef SUP_SECTION_MACRO_OPERATIONS_ON_STRUCT_AND_ITS_MEMBERS
//*************************************************************************
// So, there is a type (primitive or struct), and we do various things with it.
// As you can see below, all operations are defined by providing 3 macros:
//
// BEG_yourOperation(...) -- called once in beginning
// MEM_yourOperation(...) -- called for each member variable of the struct (unless its primitive type like float)
// END_yourOperation(...) -- called once in the end
//
// Ofcourse, you have to include all arguments, even if you dont use them.
//  
// Then, you could say: i want 'yourOperation' done on struct type 'Kek'
// and it would work.
//
// See cases below.
// Lowercase args stand for unused.
// By the way, pass ~ for unused argument (just a convention)
//
// Typically arg is called STRTYPE, but this is also potentially used with primitive types like float.
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

FOR_EACH_SUPPORTED_NATIVE_TYPE(SAVE_NATIVE_TYPE_SIZE)


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
#define MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX) MEMBEROFFSET_VARNAME_INT(STRTYPE, SUP_EVAL(MEMBERIDX))


//We save offset 0 for memberidx = 0 to variable
#define BEG_SAVEFIRSTMEMBEROFFSET(STRTYPE, strname, strdataidx)	\
	const int MEMBEROFFSET_VARNAME_FIN(STRTYPE, 0) = 0;
#define MEM_SAVEFIRSTMEMBEROFFSET(strtype, membertype, membername, strname, memberidx, strdataidx)
#define END_SAVEFIRSTMEMBEROFFSET(strtype, size)


//Then, for each memberidx we save offset for memberidx+1 (yes, we ll end up with one extra variable in the end, but we dont care)
#define BEG_SAVENEXTMEMBEROFFSETS(strtype, strname, strdataidx)
#define MEM_SAVENEXTMEMBEROFFSETS(STRTYPE, MEMBERTYPE, membername, strname, MEMBERIDX, strdataidx)	\
			const int MEMBEROFFSET_VARNAME_FIN(STRTYPE, SUP_GET_PLUS_ONE(MEMBERIDX)) = 			\
				MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX) + TYPESIZE_VARNAME(MEMBERTYPE);
#define END_SAVENEXTMEMBEROFFSETS(strtype, size)


//add more if you need more supported struct nesting levels
#ifndef MAKEGETTERS_MACROS_FOR_DIFFERENT_LEVELS

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

#define BEG_MAKEGETTERS_L3(STRTYPE, STRNAME, STRDATAIDX) \
			MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS_L3(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
			GETMETA(MEMBERTYPE)( MAKEGETTERS_L4, 											\
								 CATNAMEPATH(STRNAME, MEMBERNAME), 							\
								 STRDATAIDX + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX),	\
								 4 )
#define END_MAKEGETTERS_L3(strtype, size)

#define BEG_MAKEGETTERS_L4(STRTYPE, STRNAME, STRDATAIDX) \
			MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS_L4(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
			GETMETA(MEMBERTYPE)( MAKEGETTERS_L5, 											\
								 CATNAMEPATH(STRNAME, MEMBERNAME), 							\
								 STRDATAIDX + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX),	\
								 5 )
#define END_MAKEGETTERS_L4(strtype, size)

#endif

#define BEG_MAKEGETTERS(STRTYPE, STRNAME, STRDATAIDX) \
		BEG_MAKEGETTERS_L0(STRTYPE, STRNAME, STRDATAIDX)
#define MEM_MAKEGETTERS(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX) \
		MEM_MAKEGETTERS_L0(STRTYPE, MEMBERTYPE, MEMBERNAME, STRNAME, MEMBERIDX, STRDATAIDX)
#define END_MAKEGETTERS(strtype, size)	\
		END_MAKEGETTERS_L0(strtype, size)



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



#endif

//Generation result is in section just below that one.
#ifdef TYPEMAIN_GENERATION_PYTHON_SCRIPT
/*
exec("""
membercountfrom = 0
membercountto = 20

levelfrom = 0
levelto = 4

begline = "BEG_ ## V(T, N, I) "

for level in range(levelfrom, levelto+1):
    for membercount in range(membercountfrom, membercountto+1):
        endline = f"END_ ## V(T, {membercount})\n"
    
        defline_mid = "" 
        for memberIdx in range(0, membercount):
            defline_mid += f", T{memberIdx}, N{memberIdx}"
        defline_mid += ") "

        defline = f"#define TYPEMAIN_{membercount}MEMBERS_L{level}(T, V, N, I" + defline_mid
        
        memline = ""
        for memberIdx in range(0, membercount):
            memvar = f"MEM_ ## V(T, T{memberIdx}, N{memberIdx}, N, {memberIdx}, I) "
            memline += memvar + " "
    
        finalstr = defline + begline + memline + endline
        print(finalstr)
""")
*/
#endif

//See section above for script which generated this.
#ifndef TYPEMAIN_AUTOGENERATED
//***************************************************************************
//T: type of struct
//V: macro version for pattern matching ('yourOperation' from example above),
//N: name of struct,
//I: index in sup_data array where this variable begins
//T0/N0 ...: are type/name pairs for struct members
//
//Note that 0MEMBERS are used for non-struct, native types such as 'float'.
//The L0 - LN versions are exactly the same, but we need different names to 
//allow recursion.
//******************AUTOGENERATED WITH PYTHON********************************
#define TYPEMAIN_0MEMBERS_L0(T, V, N, I) BEG_ ## V(T, N, I) END_ ## V(T, 0)

#define TYPEMAIN_1MEMBERS_L0(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define TYPEMAIN_2MEMBERS_L0(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define TYPEMAIN_3MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define TYPEMAIN_4MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define TYPEMAIN_5MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  END_ ## V(T, 5)

#define TYPEMAIN_6MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  END_ ## V(T, 6)

#define TYPEMAIN_7MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  END_ ## V(T, 7)

#define TYPEMAIN_8MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  END_ ## V(T, 8)

#define TYPEMAIN_9MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  END_ ## V(T, 9)

#define TYPEMAIN_10MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  END_ ## V(T, 10)

#define TYPEMAIN_11MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  END_ ## V(T, 11)

#define TYPEMAIN_12MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  END_ ## V(T, 12)

#define TYPEMAIN_13MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  END_ ## V(T, 13)

#define TYPEMAIN_14MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  END_ ## V(T, 14)

#define TYPEMAIN_15MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  END_ ## V(T, 15)

#define TYPEMAIN_16MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  END_ ## V(T, 16)

#define TYPEMAIN_17MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  END_ ## V(T, 17)

#define TYPEMAIN_18MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  END_ ## V(T, 18)

#define TYPEMAIN_19MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  END_ ## V(T, 19)

#define TYPEMAIN_20MEMBERS_L0(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18, T19, N19) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  MEM_ ## V(T, T19, N19, N, 19, I)  END_ ## V(T, 20)

#define TYPEMAIN_0MEMBERS_L1(T, V, N, I) BEG_ ## V(T, N, I) END_ ## V(T, 0)

#define TYPEMAIN_1MEMBERS_L1(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define TYPEMAIN_2MEMBERS_L1(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define TYPEMAIN_3MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define TYPEMAIN_4MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define TYPEMAIN_5MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  END_ ## V(T, 5)

#define TYPEMAIN_6MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  END_ ## V(T, 6)

#define TYPEMAIN_7MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  END_ ## V(T, 7)

#define TYPEMAIN_8MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  END_ ## V(T, 8)

#define TYPEMAIN_9MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  END_ ## V(T, 9)

#define TYPEMAIN_10MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  END_ ## V(T, 10)

#define TYPEMAIN_11MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  END_ ## V(T, 11)

#define TYPEMAIN_12MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  END_ ## V(T, 12)

#define TYPEMAIN_13MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  END_ ## V(T, 13)

#define TYPEMAIN_14MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  END_ ## V(T, 14)

#define TYPEMAIN_15MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  END_ ## V(T, 15)

#define TYPEMAIN_16MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  END_ ## V(T, 16)

#define TYPEMAIN_17MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  END_ ## V(T, 17)

#define TYPEMAIN_18MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  END_ ## V(T, 18)

#define TYPEMAIN_19MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  END_ ## V(T, 19)

#define TYPEMAIN_20MEMBERS_L1(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18, T19, N19) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  MEM_ ## V(T, T19, N19, N, 19, I)  END_ ## V(T, 20)

#define TYPEMAIN_0MEMBERS_L2(T, V, N, I) BEG_ ## V(T, N, I) END_ ## V(T, 0)

#define TYPEMAIN_1MEMBERS_L2(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define TYPEMAIN_2MEMBERS_L2(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define TYPEMAIN_3MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define TYPEMAIN_4MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define TYPEMAIN_5MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  END_ ## V(T, 5)

#define TYPEMAIN_6MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  END_ ## V(T, 6)

#define TYPEMAIN_7MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  END_ ## V(T, 7)

#define TYPEMAIN_8MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  END_ ## V(T, 8)

#define TYPEMAIN_9MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  END_ ## V(T, 9)

#define TYPEMAIN_10MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  END_ ## V(T, 10)

#define TYPEMAIN_11MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  END_ ## V(T, 11)

#define TYPEMAIN_12MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  END_ ## V(T, 12)

#define TYPEMAIN_13MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  END_ ## V(T, 13)

#define TYPEMAIN_14MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  END_ ## V(T, 14)

#define TYPEMAIN_15MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  END_ ## V(T, 15)

#define TYPEMAIN_16MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  END_ ## V(T, 16)

#define TYPEMAIN_17MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  END_ ## V(T, 17)

#define TYPEMAIN_18MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  END_ ## V(T, 18)

#define TYPEMAIN_19MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  END_ ## V(T, 19)

#define TYPEMAIN_20MEMBERS_L2(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18, T19, N19) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  MEM_ ## V(T, T19, N19, N, 19, I)  END_ ## V(T, 20)

#define TYPEMAIN_0MEMBERS_L3(T, V, N, I) BEG_ ## V(T, N, I) END_ ## V(T, 0)

#define TYPEMAIN_1MEMBERS_L3(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define TYPEMAIN_2MEMBERS_L3(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define TYPEMAIN_3MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define TYPEMAIN_4MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define TYPEMAIN_5MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  END_ ## V(T, 5)

#define TYPEMAIN_6MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  END_ ## V(T, 6)

#define TYPEMAIN_7MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  END_ ## V(T, 7)

#define TYPEMAIN_8MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  END_ ## V(T, 8)

#define TYPEMAIN_9MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  END_ ## V(T, 9)

#define TYPEMAIN_10MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  END_ ## V(T, 10)

#define TYPEMAIN_11MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  END_ ## V(T, 11)

#define TYPEMAIN_12MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  END_ ## V(T, 12)

#define TYPEMAIN_13MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  END_ ## V(T, 13)

#define TYPEMAIN_14MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  END_ ## V(T, 14)

#define TYPEMAIN_15MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  END_ ## V(T, 15)

#define TYPEMAIN_16MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  END_ ## V(T, 16)

#define TYPEMAIN_17MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  END_ ## V(T, 17)

#define TYPEMAIN_18MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  END_ ## V(T, 18)

#define TYPEMAIN_19MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  END_ ## V(T, 19)

#define TYPEMAIN_20MEMBERS_L3(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18, T19, N19) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  MEM_ ## V(T, T19, N19, N, 19, I)  END_ ## V(T, 20)

#define TYPEMAIN_0MEMBERS_L4(T, V, N, I) BEG_ ## V(T, N, I) END_ ## V(T, 0)

#define TYPEMAIN_1MEMBERS_L4(T, V, N, I, T0, N0) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  END_ ## V(T, 1)

#define TYPEMAIN_2MEMBERS_L4(T, V, N, I, T0, N0, T1, N1) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  END_ ## V(T, 2)

#define TYPEMAIN_3MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  END_ ## V(T, 3)

#define TYPEMAIN_4MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  END_ ## V(T, 4)

#define TYPEMAIN_5MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  END_ ## V(T, 5)

#define TYPEMAIN_6MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  END_ ## V(T, 6)

#define TYPEMAIN_7MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  END_ ## V(T, 7)

#define TYPEMAIN_8MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  END_ ## V(T, 8)

#define TYPEMAIN_9MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  END_ ## V(T, 9)

#define TYPEMAIN_10MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  END_ ## V(T, 10)

#define TYPEMAIN_11MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  END_ ## V(T, 11)

#define TYPEMAIN_12MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  END_ ## V(T, 12)

#define TYPEMAIN_13MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  END_ ## V(T, 13)

#define TYPEMAIN_14MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  END_ ## V(T, 14)

#define TYPEMAIN_15MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  END_ ## V(T, 15)

#define TYPEMAIN_16MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  END_ ## V(T, 16)

#define TYPEMAIN_17MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  END_ ## V(T, 17)

#define TYPEMAIN_18MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  END_ ## V(T, 18)

#define TYPEMAIN_19MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  END_ ## V(T, 19)

#define TYPEMAIN_20MEMBERS_L4(T, V, N, I, T0, N0, T1, N1, T2, N2, T3, N3, T4, N4, T5, N5, T6, N6, T7, N7, T8, N8, T9, N9, T10, N10, T11, N11, T12, N12, T13, N13, T14, N14, T15, N15, T16, N16, T17, N17, T18, N18, T19, N19) BEG_ ## V(T, N, I) MEM_ ## V(T, T0, N0, N, 0, I)  MEM_ ## V(T, T1, N1, N, 1, I)  MEM_ ## V(T, T2, N2, N, 2, I)  MEM_ ## V(T, T3, N3, N, 3, I)  MEM_ ## V(T, T4, N4, N, 4, I)  MEM_ ## V(T, T5, N5, N, 5, I)  MEM_ ## V(T, T6, N6, N, 6, I)  MEM_ ## V(T, T7, N7, N, 7, I)  MEM_ ## V(T, T8, N8, N, 8, I)  MEM_ ## V(T, T9, N9, N, 9, I)  MEM_ ## V(T, T10, N10, N, 10, I)  MEM_ ## V(T, T11, N11, N, 11, I)  MEM_ ## V(T, T12, N12, N, 12, I)  MEM_ ## V(T, T13, N13, N, 13, I)  MEM_ ## V(T, T14, N14, N, 14, I)  MEM_ ## V(T, T15, N15, N, 15, I)  MEM_ ## V(T, T16, N16, N, 16, I)  MEM_ ## V(T, T17, N17, N, 17, I)  MEM_ ## V(T, T18, N18, N, 18, I)  MEM_ ## V(T, T19, N19, N, 19, I)  END_ ## V(T, 20)


//******************AUTOGENERATED WITH PYTHON*************************
#endif

#ifndef SUP_CORE_LOGIC_PUTTING_IT_ALL_TOGETHER

//Since every native variable is stored in vec4 in sup_data array, heres how we restore:
float 	sup_as_float	(vec4 v) {return v.x;	}
vec2 	sup_as_vec2		(vec4 v) {return v.xy;	}
vec3 	sup_as_vec3		(vec4 v) {return v.xyz;	}
vec4 	sup_as_vec4		(vec4 v) {return v;		}
int 	sup_as_int		(vec4 v) {return int(v.x + 0.5);			}
ivec2 	sup_as_ivec2	(vec4 v) {return ivec2(v.xy + vec2(0.5));	}
ivec3 	sup_as_ivec3	(vec4 v) {return ivec3(v.xyz + vec3(0.5));	}
ivec4 	sup_as_ivec4	(vec4 v) {return ivec4(v + vec4(0.5));		}


//As explained above, these defines do nothing; C++ QtouchApp looks for these tags
#define SUP_VARS_BEGIN 
#define SUP_VARS_END


#define SUP_DATA_FINAL_INDEX(VARIDX, STRTYPE, MEMBERIDX) (VARSUPDATAIDX_VARNAME_FIN(VARIDX) + MEMBEROFFSET_VARNAME_FIN(STRTYPE, MEMBERIDX))

#define VARSUPDATAIDX_VARNAME_IMP(VARIDX) sup_data_index_for_varidx_ ## VARIDX
#define VARSUPDATAIDX_VARNAME_INT(VARIDX) VARSUPDATAIDX_VARNAME_IMP(VARIDX)
//Use only this one. The meaning of variable: at which index in sup_data array does item at VARIDX in SUP_VARLIST begin.
#define VARSUPDATAIDX_VARNAME_FIN(VARIDX) VARSUPDATAIDX_VARNAME_INT(SUP_EVAL(VARIDX))

//We just save initial here. First item begins at 0.
const int VARSUPDATAIDX_VARNAME_FIN(0) = 0;


#define SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(THISVARIDX, THISVARIDXTYPE) \
			const int VARSUPDATAIDX_VARNAME_FIN(SUP_GET_PLUS_ONE(THISVARIDX)) = \
				VARSUPDATAIDX_VARNAME_FIN(THISVARIDX) + TYPESIZE_VARNAME(THISVARIDXTYPE);



#define GETMETA(STRTYPE) 		TYPEMETA_ ## STRTYPE

#define ui(data_for_cpp_to_parse_its_completely_unused_by_shader)
 
#define SUP_STRDECL(STRTYPE) 	GETMETA(STRTYPE)(DECLSTRUCT, 			~, ~, 0)\
								GETMETA(STRTYPE)(SAVETYPESIZE, 			~, ~, 0)\
								GETMETA(STRTYPE)(SAVEFIRSTMEMBEROFFSET, ~, ~, 0)\
								GETMETA(STRTYPE)(SAVENEXTMEMBEROFFSETS, ~, ~, 0)
								

//Func argument: (int supDataIndex)
#define GETVARATINDEX_FUNCNAME(TYPENAME) getVarAtSupDataIndex_ ## TYPENAME

#define TYPEMAIN(MEMBERSCOUNT, LEVEL) TYPEMAIN_ ## MEMBERSCOUNT ## MEMBERS_L ## LEVEL 


//just to convey meaning better
#define FOR_EACH_VARLIST_ENTRY(FUNCVISITOR) SUP_VARLIST(FUNCVISITOR)
#define FOR_EACH_CUSTOMTYPE(FUNCVISITOR) SUP_LIST_OF_ALL_STRUCT_TYPES_USED_IN_VARLIST(FUNCVISITOR)

#define PLUS_SIZE_OF_VARLIST_ENTRY(varidx, STRTYPE, strname) + TYPESIZE_VARNAME(STRTYPE)


#define SUP_VARLIST_SIZE ( FOR_EACH_VARLIST_ENTRY(PLUS_SIZE_OF_VARLIST_ENTRY) )


#define MAKE_GETVARATINDEX_FUNC_FOR_NATIVE_TYPE(TYPE) 	\
	TYPE GETVARATINDEX_FUNCNAME(TYPE) (int supDataIndex)\
	{													\
		return sup_as_ ## TYPE (sup_data[supDataIndex]);\
	}
			
#define MAKE_GETVARATINDEX_FUNC_FOR_CUSTOM_TYPE(STRTYPE) 	\
	GETMETA(STRTYPE)(MAKEGETVARATINDEXFUNC, ~, ~, 0)


//This is needed for MAKEGETTERS macros
#define TYPEMETA_float(V,N,I,L) TYPEMAIN(0,L)(float,V,N,I)
#define TYPEMETA_vec2(V,N,I,L) 	TYPEMAIN(0,L)(vec2,	V,N,I)
#define TYPEMETA_vec3(V,N,I,L) 	TYPEMAIN(0,L)(vec3,	V,N,I)
#define TYPEMETA_vec4(V,N,I,L) 	TYPEMAIN(0,L)(vec4,	V,N,I)
#define TYPEMETA_int(V,N,I,L) 	TYPEMAIN(0,L)(int,	V,N,I)
#define TYPEMETA_ivec2(V,N,I,L)	TYPEMAIN(0,L)(ivec2,V,N,I)
#define TYPEMETA_ivec3(V,N,I,L)	TYPEMAIN(0,L)(ivec3,V,N,I)
#define TYPEMETA_ivec4(V,N,I,L)	TYPEMAIN(0,L)(ivec4,V,N,I)

#define CATNAMEPATH_INNER(NAMEPATH, MEMBERNAME) NAMEPATH ## _ ## MEMBERNAME
#define CATNAMEPATH(NAMEPATH, MEMBERNAME) CATNAMEPATH_INNER(NAMEPATH, MEMBERNAME)

#define MAKE_GETTER_FUNC(STRTYPE, STRNAME, STRDATAIDX) 		\
	STRTYPE STRNAME()										\
	{														\
		return GETVARATINDEX_FUNCNAME(STRTYPE) (STRDATAIDX);\
	}


#define INIT_VARLIST_ENTRY(VARIDX, STRTYPE, STRNAME) 				\
			SAVE_VARSUPDATAIDX_FOR_NEXT_VARIDX(VARIDX, STRTYPE)		\
			GETMETA(STRTYPE)(MAKEGETTERS, STRNAME, VARSUPDATAIDX_VARNAME_FIN(VARIDX), 0)
			

#define SUP_INITIALIZE_VARLIST 														\
			uniform vec4 sup_data[SUP_VARLIST_SIZE];								\
			FOR_EACH_SUPPORTED_NATIVE_TYPE(MAKE_GETVARATINDEX_FUNC_FOR_NATIVE_TYPE)	\
			FOR_EACH_CUSTOMTYPE(MAKE_GETVARATINDEX_FUNC_FOR_CUSTOM_TYPE)			\
			FOR_EACH_VARLIST_ENTRY(INIT_VARLIST_ENTRY)

#endif