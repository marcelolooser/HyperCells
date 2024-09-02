# HELPER FUNCTIONS, EXTENSIONS 

# Dependencies:
# - Internal.g
# - kbmag package 1.5.10+

# Constructs rewriting systems (rws) via Knuth-Bendix completion algorithm
# and stores it in cache.
rwsFunc@ := MemoizePosIntFunction(function(ID)
	local G, ORkbrws, maxlen, kbrws, mhom, mon, catch, lenRules, lmax;
	
	# Get needed input through options:
	# --------------------------------
	lmax := ValueOption("lmax");
	G := ValueOption("group");

	# ---------------------
	# Set up kbrws options:
 	# ---------------------

	# maximal word length left and right
	# (somewhat arbitrary due to the nature of the algorithm (see documentation)
	#  however, this is a rather stable, minimal choice)
	maxlen := [lmax, 2*(1+lmax)]; 
       	
	# reduce group to monoid
	mhom := IsomorphismFpMonoid(G);
       	mon := Image(mhom);
      	kbrws := KBMAGRewritingSystem(mon);	
	
	# ---------------
	# Adjust options:
	# ---------------
	# in order to halt in a reasonable amount of time

	# SetOrderingOfKBMAGRewritingSystem(kbrws, "recursive"); # alternative method
       	ORkbrws := OptionsRecordOfKBMAGRewritingSystem(kbrws);
   	ORkbrws.maxstoredlen := maxlen; # set maximal word length left and right

	# ---------------------------------------
       	# Construct (probably non-confluent) rws:
	# ---------------------------------------

	# occuring errors are "caught" (assuming SimplifyWord@ uses BreakOnError := false when entered) 
       	catch := CALL_WITH_CATCH(KnuthBendix, [kbrws])[1];; # alternative: use ErrorCount
	
	# ---------------------------------------------
	# Throw warning due to possibly occured errors:
	# ---------------------------------------------

	if not catch then
		lenRules := Length(Rules(kbrws));

		# error due the above defined options occurred
		# (or unexpected error occurred) TODO: catch unexpected error separately
		if Length(Rules(kbrws)[lenRules, 1]) + Length(Rules(kbrws)[lenRules, 2]) > maxlen[1] + maxlen[2] then
			Print("#WARNING: simplification was unsuccessful; non-simplified words will be used.\n");
			Print(StringFormatted("Try setting simplify to a value above {}.", lmax + 1));
		
		# error due to missing configurations in the package kbmag occurred 
		# (or (highly unlikely) possibly due to exceeding 65535 number of generators)
		else
			Print("#WARNING: maximal number of genartors have been exceeded; non-simplified words will be used.\n");
			Print("Please follow the instructions in the chapter Introduction, section Simplify extension (optional) in the HyperCells reference manual.");
		fi;
		return catch;
	else
		return [kbrws, mhom, mon, G];
	fi;
end );

# SimplifyWord@ function extensions which add to the original brute force method
# a rewriting system method via the Knuth-Bendix completion algorithm 
SimplifyWord@ := function(G, w, lmax)
    local method, availableMethods, homcache, rhomcache, lw, gens, l, tuple, w2, RWS, 
     ORkbrws, kbrws, mhom, mon, melm, melm2, red, ID;

    # Intitialize:
    # ------------
    availableMethods := ["BruteForce", "KnuthBendix"];

    # --------
    # Options:
    # --------     

    method := ValueOption("simplifyMethod");
    if method = fail or not IsString(method) or (IsString(method) and not method in availableMethods) then 
	method := "BruteForce";
    fi;

    # --------------
    # Preliminaries:
    # --------------

    if IsOne(w) then
        return One(G);
    fi;

    lw := Length(w);
    if lw <= 1 then
        return w;
    fi;
   
    if lmax < 0 then
	lmax := lw;
    elif lmax = 0 then
	return w;
    fi;

    # generators and inverses
    gens := GeneratorsOfGroup(G);
    gens := Concatenation(gens, List(gens, g -> g^-1));

    # ----------------------------
    # Perform word simplification:
    # ----------------------------
    
    # Brute force method:
    # -------------------
    if method = "BruteForce" then

        for l in [1 .. Minimum(lw-1, lmax)] do
            # generate all words of length l and check equivalence
            for tuple in IteratorOfCartesianProduct(List([1 .. l], i -> gens)) do
                w2 := ListProduct@(tuple);
                if w2 = w then
                    return w2;
                fi;
            od;
        od;

        return w;

    # Knuth-Bendinx method:
    # ---------------------
    elif method = "KnuthBendix" then
	
	# -----------------------
	# Avoid too small inputs:
	# -----------------------
	# this makes it unlikely that rewriting systems
	# for the same group are generated multiple times 
	# and that the choosen options in rwsFunc@ do not 
	# lead to unintended errors (or at least it seems rather stable)
	if lmax < Length(gens) then 
		lmax := Length(gens);
	fi;
	
	# -------------
	# Construct ID:
	# -------------
	# for memoize function in rwsFunc@, (string to positive integer)
	ID := AbsInt(CrcString(JoinStringsWithSeparator([String(gens), String(RelatorsOfFpGroup(G))],"")));
	
	# ---------------------------
	# Construct rewriting system:
	# ---------------------------
	BreakOnError := false; # avoid break loops
	RWS := rwsFunc@(ID : group := G, lmax := lmax);
	BreakOnError := true; # restore default setting

	# ------------------------------
	# Try to simplify provided word:
	# ------------------------------

	# if an error occured, return original word
	if IsBool(RWS) then
		return w;

	# if not try to simplify provided word
	else 
		# rewriting system, homomorphism and monoid
		kbrws := RWS[1]; mhom := RWS[2]; mon:= RWS[3];

		# The following part is needed since the same groups are constructed
		# multiple times in the main code. (possible optimization)
		homcache := GroupHomomorphismByImagesNC(RWS[4], G);
		rhomcache := InverseGeneralMapping(homcache);
		w := PreImagesRepresentative(homcache, w);

        	# transform and return w
        	melm := Image(mhom, w); # image of word in monoid
        	red := ReducedForm(kbrws, UnderlyingElement(melm)); # simplify word
        	melm2 := ElementOfFpMonoid(FamilyObj(One(mon)), red); # get simplified word
		red := PreImagesRepresentative(mhom, melm2); # find preimage in monoid
        	return PreImagesRepresentative(rhomcache, red); # return preimage in group G
	fi;
    fi;
end;

