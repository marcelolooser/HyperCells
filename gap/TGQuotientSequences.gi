InstallGlobalFunction( ExtendTGQuotientSequence,
function(quotient, sequence)
    local sgn, tg, D, Q, Q0, GAM0, GAM1, ind, hom, G, iso, isosimp, Gfp, relsfp,
        comp, rels, extseq, GAMtilde, Q1;

    # triangle group
    sgn := TriangleGroupSignature(sequence[1]);
    tg := ProperTriangleGroup(sgn);
    D := FpGroup(tg);

    # check sequence
    if not IsTGQuotientSequence(sequence) then
        Error(StringFormatted("The sequence {} is not a valid sequence of quotient groups.", sequence));
        return fail;
    fi;
    # for Q in sequence do
    #     if not TriangleGroupSignature(Q) = sgn then
    #         Error(StringFormatted("The quotient {} is not a quotient of the triangle group with signature {}.", TGQuotientName(Q), sgn));
    #         return fail;
    #     fi;

    #     # translation group
    #     GAM1 := AsTGSubgroup(TGTranslationGroupFromQuotient(D, D / TGQuotientRelators(tg, Q)));

    #     # check if (normal) subgroup
    #     if IsBound(GAM0) then
    #         if not (IsSubgroup(GAM0, GAM1) and IsNormal(GAM0, GAM1)) then
    #             Error(StringFormatted("The quotient {} does not lead to a translation group that is a normal subgroup of the previous one.", TGQuotientName(Q), sgn));
    #             return fail;
    #         fi;
    #     fi;

    #     GAM0 := GAM1;
    #     Append(GAMs, [GAM0]);
    # od;

    # last translation group of existing sequence
    Q0 := sequence[Length(sequence)];
    GAM0 := AsTGSubgroup(TGTranslationGroupFromQuotient(
        D, D / TGQuotientRelators(tg, Q0), TGQuotientGenus(Q0)
    ));

    # extend sequence of translation group
    extseq := [];
    for Q in quotient do
        if not IsTGQuotientObj(Q) then
            Error(StringFormatted("The quotient {} is not a TGQuotient object.", Q));
            return fail;
        fi;
        if not TriangleGroupSignature(Q) = sgn then
            Error(StringFormatted("The quotient {} is not a quotient of the triangle group with signature {}.", TGQuotientName(Q), sgn));
        fi;

        GAMtilde := AsTGSubgroup(TGTranslationGroupFromQuotient(
            D, D / TGQuotientRelators(tg, Q), TGQuotientGenus(Q)
        ));

        GAM1 := Intersection(GAM0, GAMtilde);
        ind := Index(GAM0, GAM1);
        if ind > 1 then
            hom := NaturalHomomorphismByNormalSubgroup(D, GAM1); # D -> G
            G := Image(hom, D);
            iso := IsomorphismFpGroupByGenerators(G, GeneratorsOfGroup(G)); # G -> Gfp
            Gfp := Image(iso, G);
            isosimp := IsomorphismSimplifiedFpGroup(Gfp : protected := 3); # Gfp -> Gfp'
            Gfp := Image(isosimp, Gfp);
            relsfp := List(RelatorsOfFpGroup(Gfp), rel -> ElementOfFpGroup(FamilyObj( Gfp.1 ), rel));
            comp := CompositionMapping(isosimp, iso, hom);
            rels := List(relsfp, rel -> PreImagesRepresentative(comp, rel));
            Q1 := Objectify( NewType(
                NewFamily( "TGQuotient", IsTGQuotientObj ),
                IsTGQuotientObj and IsTGQuotientComponentRep),
                rec(
                    name := MakeImmutable(StringFormatted("{1} v {2}", TGQuotientName(Q0), TGQuotientName(Q))),
                    triangle := sgn, 
                    order := Order(Gfp),
                    genus := 1+ind*(TGQuotientGenus(Q0)-1),
                    action := MakeImmutable("unknown"),
                    relators := MakeImmutable(PrintString(rels))
                )
            );
            Append(extseq, [ Q1 ]);
            GAM0 := GAM1;
            Q0 := Q1;
        fi;
    od;

    # return extended sequence
    return Concatenation(sequence, extseq);
end );

InstallGlobalFunction( NextTGQuotientOptions,
function(quotient, Q0)
    local sgn, tg, D, GAM0, opts, Q, GAMtilde, GAM1, ind;

    # check arguments
    if not IsTGQuotientObj(Q0) then
        Error(StringFormatted("The quotient {} is not a TGQuotient object.", Q0));
        return fail;
    fi;

    # triangle group
    sgn := TriangleGroupSignature(Q0);
    tg := ProperTriangleGroup(sgn);
    D := FpGroup(tg);

    # last translation group of existing sequence
    GAM0 := AsTGSubgroup(TGTranslationGroupFromQuotient(
        D, D / TGQuotientRelators(tg, Q0), TGQuotientGenus(Q0)
    ));

    # iterate over options for extension
    opts := [];
    for Q in quotient do
        if not IsTGQuotientObj(Q) then
            Error(StringFormatted("The quotient {} is not a TGQuotient object.", Q));
            return fail;
        fi;
        if not TriangleGroupSignature(Q) = sgn then
            Error(StringFormatted("The quotient {} is not a quotient of the triangle group with signature {}.", TGQuotientName(Q), sgn));
        fi;

        GAMtilde := AsTGSubgroup(TGTranslationGroupFromQuotient(
            D, D / TGQuotientRelators(tg, Q), TGQuotientGenus(Q)
        ));

        GAM1 := Intersection(GAM0, GAMtilde);
        ind := Index(GAM0, GAM1);
        if ind > 1 then
            Append(opts, [ [ Q, ind ] ]);
        fi;
    od;

    SortBy(opts, opt -> opt[2]);

    return opts;
end );

InstallGlobalFunction( ExtendTGQuotientSequencesWithMinimalIndex,
function(seqs, n)
    local sgn, tg, D, sequence, sequences, quotients, qlists, GAMs, i, j, jp, k, Q, GAM0, Q0, GAM1next, indmin, GAM1, ind, hom, G, iso, Gfp, relsfp, comp, rels, GAMtilde, Qnew;

    # triangle group
    sgn := TriangleGroupSignature(seqs[1][1]);
    tg := ProperTriangleGroup(sgn);
    D := FpGroup(tg);

    # check sequences
    for sequence in seqs do
        if not IsTGQuotientSequence(sequence) then
            Error(StringFormatted("The sequence {} is not a valid sequence of quotient groups.", sequence));
            return fail;
        fi;
    od;
    # Print("All sequences are fine.\n");

    sequences := StructuralCopy(seqs);

    # quotients
    quotients := [];
    GAMs := [];
    for j in [1..Length(sequences)] do
        for k in [1..Length(sequences[j])] do
            if not sequences[j][k] in quotients then
                Append(quotients, [ sequences[j][k] ]);
                Append(GAMs, [ AsTGSubgroup(TGTranslationGroupFromQuotient(
                    D, D / TGQuotientRelators(tg, sequences[j][k]),
                    TGQuotientGenus(sequences[j][k])
                )) ]);
            fi;
        od;
    od;

    qlists := List([1..Length(sequences)], j -> ShallowCopy(quotients));
    for j in [1..Length(sequences)] do
        k := 1;
        while k <= Length(qlists[j]) do
            if qlists[j][k] in sequences[j] then
                Remove(qlists[j], k);
            else
                k := k+1;
            fi;
        od;
    od;

    for i in [1..n] do # extend sequences by n steps
        # Print("Extension round ", i, ".\n");

        for j in [1..Length(sequences)] do
            sequence := sequences[j];
            # Print("  Sequence ", j, ".\n");

            # last translation group of existing sequence
            Q0 := sequence[Length(sequence)];
            GAM0 := GAMs[Position(quotients, Q0)];

            # iterate over options for extension
            indmin := 0;
            k := 1;
            while k <= Length(qlists[j]) do
                Q := qlists[j][k];
                if not TriangleGroupSignature(Q) = sgn then
                    Error(StringFormatted("The quotient {} is not a quotient of the triangle group with signature {}.", TGQuotientName(Q), sgn));
                fi;
                # Print("    Check index of ", Q, ": ");
                if indmin <= 1 or  not TGQuotientOrder(Q)/TGQuotientOrder(sequence[Length(sequence)]) > indmin then
                    GAMtilde := AsTGSubgroup(TGTranslationGroupFromQuotient(
                        D, D / TGQuotientRelators(tg, Q), TGQuotientGenus(Q)
                    ));

                    GAM1 := Intersection(GAM0, GAMtilde);
                    ind := Index(GAM0, GAM1);
                    # Print(ind, ".\n");
                    if ind > 1 then
                        if indmin <= 1 or ind < indmin then
                            indmin := ind;
                            GAM1next := GAM1;
                        fi;
                        k := k+1;
                    else
                        Remove(qlists[j], k);
                    fi;
                else
                    k := k+1;
                    # Print("> ", indmin, ".\n");
                fi;
            od;

            # Print("  Minimal index: ", indmin, ".\n");

            # extend sequence of translation group
            if indmin > 1 then
                # Print("  Construct quotient.\n");
                hom := NaturalHomomorphismByNormalSubgroup(D, GAM1next);
                G := Image(hom, D);
                iso := IsomorphismFpGroupByGenerators(G, GeneratorsOfGroup(G));
                Gfp := Image(iso, G);
                relsfp := List(RelatorsOfFpGroup(Gfp), rel -> ElementOfFpGroup(FamilyObj( Gfp.1 ), rel));
                comp := CompositionMapping(iso, hom);
                rels := List(relsfp, rel -> PreImagesRepresentative(comp, rel));
                Qnew := Objectify( NewType(
                    NewFamily( "TGQuotient", IsTGQuotientObj ),
                    IsTGQuotientObj and IsTGQuotientComponentRep),
                    rec(
                        name := [1+indmin*(TGQuotientGenus(Q0)-1), "?"],
                        triangle := sgn, 
                        order := Order(Gfp),
                        genus := 1+indmin*(TGQuotientGenus(Q0)-1),
                        action := "unknown",
                        relators := PrintString(rels)
                    )
                );
                Append(sequences[j], [ Qnew ]);
                for jp in [1..Length(sequences)] do
                    if not jp = j then
                        Append(qlists[jp], [ Qnew ]);
                        if not Qnew in quotients then
                            Append(quotients, [ Qnew ]);
                            Append(GAMs, [ GAM1next ]);
                        fi;
                    fi;
                od;
                # Print("  Done.\n");
            fi;
        od;
    od;

    # return extended sequences
    return sequences;
end );

InstallGlobalFunction( ExportTGQuotientList,
function(list, path)
	local output, Q;

	# open file
	output := OutputTextFile(path, false);
	SetPrintFormattingStatus(output, false);

    # iterate over quotients
    for Q in list do
        AppendTo(output, ExportString(Q));
        AppendTo(output, "\n");
    od;

	# close
	CloseStream(output);
end );

InstallGlobalFunction( ExportTGQuotientSequences,
function(seqs, path)
	local output, seq, Q;

	# open file
	output := OutputTextFile(path, false);
	SetPrintFormattingStatus(output, false);

    # iterate over quotients
    for seq in seqs do
        for Q in seq do
            AppendTo(output, ExportString(Q));
            AppendTo(output, "\n");
        od;
        AppendTo(output, "\n");
    od;

	# close
	CloseStream(output);
end );

InstallGlobalFunction( ImportTGQuotientList,
function(input)
    local str, list;

    # check arguments
	if not IsInputTextStream(input) then
		Error("The input must be a text stream.");
		return fail;
	fi;

    # list of quotients
    list := [];

    # read line by line
    str := ReadAllLine(input);
    while not str = fail do
        Append(list, [ ImportTGQuotientString(ReplacedString(str, "\n", "")) ]);
        str := ReadAllLine(input);
    od;
    
    # return list
    return list;
end );

InstallGlobalFunction( ImportTGQuotientListFromFile,
function(path)
	local input, tgquots;

	# open input stream
	input := InputTextFile(path);

	# import
	tgquots := ImportTGQuotientList(input);

	# close stream
	CloseStream(input);

	return tgquots;
end );

InstallGlobalFunction( ImportTGQuotientSequences,
function(input)
    local str, seqs, i;

    # check arguments
	if not IsInputTextStream(input) then
		Error("The first argument must be an input text stream.");
		return fail;
	fi;

    # list of sequences
    seqs := [ [] ];
    i := 1;

    # read line by line
    str := ReadAllLine(input);
    while not str = fail do
        if ReplacedString(str, "\n", "") = "" then
            i := i+1;
        else
            if i > Length(seqs) then
                Append(seqs, [ [ ] ]);
            fi;
            Append(seqs[i], [ ImportTGQuotientString(ReplacedString(str, "\n", "")) ]);
        fi;
        str := ReadAllLine(input);
    od;
    
    # return list
    return seqs;
end );

InstallGlobalFunction( ImportTGQuotientSequencesFromFile,
function(path)
	local input, tgquots;

	# open input stream
	input := InputTextFile(path);

	# import
	tgquots := ImportTGQuotientSequences(input);

	# close stream
	CloseStream(input);

	return tgquots;
end );

InstallGlobalFunction( IsTGQuotientSequence,
function(sequence)
    local sgn, tg, D, Q, GAM0, GAM1, result;

    # triangle group
    sgn := TriangleGroupSignature(sequence[1]);
    tg := ProperTriangleGroup(sgn);
    D := FpGroup(tg);

    for Q in sequence do
        if not TriangleGroupSignature(Q) = sgn then
            return false;
        fi;

        # translation group
        GAM1 := AsTGSubgroup(TGTranslationGroupFromQuotient(
            D, D / TGQuotientRelators(tg, Q), TGQuotientGenus(Q)
        ));

        # check if (normal) subgroup
        if IsBound(GAM0) then
            if not (IsSubgroup(GAM0, GAM1) and IsNormal(GAM0, GAM1)) then
                return false;
            fi;
        fi;

        GAM0 := GAM1;
    od;

    return true;
end );


# Type TGQuotientSequencesAdjacencyMatrix
DeclareRepresentation("IsTGQuotientSequencesAdjacencyMatrixComponentRep", IsComponentObjectRep,
	[ "signature", "boundByGenus", "lstTGQuotients", "lstMirrorSymmetries", "sparse", "adjMatrix" ]
);


InstallMethod( \=, [
    IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep,
    IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat1, tgQSAdjMat2)
	return 	Signature(tgQSAdjMat1) = Signature(tgQSAdjMat2) and
		BoundByGenus(tgQSAdjMat1) = BoundByGenus(tgQSAdjMat2) and
		GetListTGQuotients(tgQSAdjMat1) = GetListTGQuotients(tgQSAdjMat2) and
		MirrorSymmetries(tgQSAdjMat1) = MirrorSymmetries(tgQSAdjMat2) and
		AdjacencyMatrix(tgQSAdjMat1) = AdjacencyMatrix(tgQSAdjMat2);
end );



InstallMethod( Signature, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.signature;
end );

InstallMethod( BoundByGenus, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.boundByGenus;
end );

InstallMethod( GetListTGQuotients, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.lstTGQuotients;
end );

InstallMethod( MirrorSymmetries, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.lstMirrorSymmetries;
end );

InstallMethod( IsSparse, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.sparse;
end );

InstallMethod( AdjacencyMatrix, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return tgQSAdjMat!.adjMatrix;
end );



InstallMethod( PrintString, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	return Concatenation( "TGQuotientSequencesAdjacencyMatrix( ", 
		PrintString(Signature(tgQSAdjMat)), ", ",
		"boundByGenus = ", PrintString(BoundByGenus(tgQSAdjMat)), ", ",
		"ListTGQuotients = ", PrintString(GetListTGQuotients(tgQSAdjMat)), ", ",
		"MirrorSymmetries = ", PrintString(MirrorSymmetries(tgQSAdjMat)), ", ",
		"sparse = ", PrintString(IsSparse(tgQSAdjMat)), ", ",
		"adjMatrix = ", PrintString(AdjacencyMatrix(tgQSAdjMat)), 
	")" );
end );

InstallMethod( PrintObj, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	Print(PrintString(tgQSAdjMat));
end );


# Saves translation groups in cache
cachedGroup@ := MemoizePosIntFunction(function(conderIndex)
	local tgANDQuot;
	tgANDQuot := ValueOption("tgANDQuot");
	return AsTGSubgroup(TGTranslationGroup(tgANDQuot[1], tgANDQuot[2]));
end);

# Takes a list of integers and returns a new integer of concatenated integers in the list.
toIndex@ := function(IndexLst)
	return Int(JoinStringsWithSeparator(List(IndexLst, x -> String(x)),""));
end;

InstallGlobalFunction( TGQuotientSequencesAdjacencyMatrix,
function(tg)
	local signature, conderIndexLst, boundByGenus, lenConder, adjMat, i, j, k, l, 
         Quot1, Quot2, genus1, genus2, switch1, switch2, GAMMA1, GAMMA2, sparse, F, 
         D, DELTA, a, b, c, embDDELTA, rels, relsfull, G, Gplus, mspLst, tempRecNames;

	# Raising errors in input:
	# ------------------------

	if not IsProperTriangleGroupObj(tg) then
		Error("The first argument must be a ProperTriangleGroup object.");
		return fail;
	fi;

	# ---------------
    	# Needed objects:
    	# ---------------

	signature := Signature(tg);
	conderIndexLst := ListTGQuotients(signature);
	
	# ---------
    	# Options :
    	# ---------

	# upper bound of triangle group quotients genus
	boundByGenus := ValueOption("boundByGenus");
	if boundByGenus = fail then
		boundByGenus := 102; # Max. in Conder's list 101.
	elif not IsPosInt(boundByGenus) then
		Error(StringFormatted("boundByGenus {} is not a positive integer.", boundByGenus));
	        return fail;
	elif boundByGenus > 102 then
		Print(StringFormatted("boundByGenus {} exceeded the upper bound 102, the default value 102 was used instead.", boundByGenus));
		boundByGenus := 102; # Max. in Conder's list 101.
	fi;

	# condition for sparse rep. of adjacency matrix
    	sparse := ValueOption("sparse");
    	if sparse = fail then
    		sparse := false;
    	elif not IsBool(sparse) then
		Error(StringFormatted("The option sparse {} is not valid. It must be a boolean.", sparse));
		return fail;
    	fi;
	
	# -----------
	# Initialize:
	# -----------
	
	# restrict list of quotients according to boundByGenus
	conderIndexLst := Filtered(conderIndexLst, x -> x[1] < boundByGenus);
        lenConder := Length(conderIndexLst);

	# obj.s for mirror symmetry property (msp) of quotients:
	# proper triangle group
	D := FpGroup(tg); 
	
	# (full) triangle group and reflection generators
	DELTA := FpGroup(TriangleGroup(signature));
	a := DELTA.1;; b := DELTA.2;; c := DELTA.3;

	# embedding homomorphism of D in DELTA
	embDDELTA := GroupHomomorphismByImagesNC(D, DELTA, 
			GeneratorsOfGroup(D), [a*b, b*c, c*a]);	

	# initialize binary list of mirror symmetries
	mspLst := [1];

	# ---------------------------
	# Construct adjacency matrix:
	# ---------------------------
	
        if sparse then 
		adjMat := rec(); # adjacency matrix predecessor (will be converted to nested list in the end)
		for j in [2..Length(conderIndexLst)] do
			
			# Quot2: quotient with translation group to be compared with the 
			# translation group of quotient Quot1
			Quot2 := TGQuotient(conderIndexLst[j]);
			genus2 := TGQuotientGenus(Quot2);

			# translation group of Quot2
			GAMMA2 := cachedGroup@(toIndex@(Concatenation(signature,conderIndexLst[j])) : tgANDQuot := [tg, Quot2]);


			# Quotient mirror symmetry:
			# -----------------------------------------------
			# Check if quotient is mirror symmetric

			# point group
			rels := TGQuotientRelators(tg, Quot2);
 			Gplus := D / rels;

			# full point group
			relsfull := List(rels, r -> Image(embDDELTA, r));
			G := DELTA / relsfull;

			# Get mirror symmetry property:
			if not Order(G) = 2 * Order(Gplus) then
				Add(mspLst, 0);
			else
				Add(mspLst, 1);
			fi;
			# ------------------------------------------------
		
			# Tomas code
			for k in [1..(j - 1)] do

				i := j - k;

				# Quot1: quotient with translation group to be compared with the 
				# translation group of quotient Quot2
				Quot1 := TGQuotient(conderIndexLst[i]);
				genus1 := TGQuotientGenus(Quot1);
				
				# check Rieman-Hurwitz formula 
				if IsInt((genus2 - 1)/(genus1 - 1)) and genus2 > genus1 then

					switch2 := 0;
					for l in [(i + 1)..(j - 1)] do

						# get already present record names
						tempRecNames := RecNames(adjMat);
						
						# check if the entry already exists
						if String([i, l]) in tempRecNames and String([l, j]) in tempRecNames then
							switch2 := 1; 
							adjMat.(String([i, j])) := 1;
							break;
						fi;
					od;

					if switch2 = 0 then
						
						# translation group of Quot1
						GAMMA1 := cachedGroup@(toIndex@(Concatenation(signature,conderIndexLst[i])) : tgANDQuot := [tg, Quot1]);
						
						# check normal subgroup relation
						switch1 := IsSubset(GAMMA1, GAMMA2); # since GAMMA1 is a group IsSubset suffices
						if switch1 = true then
							adjMat.(String([i, j])) := 1;
						fi;
					fi;
				fi;
			od;
	 	od;
		# reformat record into a nested list of the form [ [[rowIdx, colIdx], entry], ... ]
		adjMat := SortedList(List(RecNames(adjMat), item -> [EvalString(item),adjMat.(item)]));
        else
        	adjMat := NullMat(lenConder, lenConder); 
		for j in [2..Length(conderIndexLst)] do
	
			# Quot2: quotient with translation group to be compared with the 
			# translation group of quotient Quot1
			Quot2 := TGQuotient(conderIndexLst[j]);
			genus2 := TGQuotientGenus(Quot2);
			GAMMA2 := cachedGroup@(toIndex@(Concatenation(signature,conderIndexLst[j])) : tgANDQuot := [tg, Quot2]);


			# Quotient mirror symmetry:
			# -----------------------------------------------
			# Check if quotient is mirror symmetric

			# point group
			rels := TGQuotientRelators(tg, Quot2);
 			Gplus := D / rels;

			# full point group
			relsfull := List(rels, r -> Image(embDDELTA, r));
			G := DELTA / relsfull;

			# Get mirror symmetry property:
			if not Order(G) = 2 * Order(Gplus) then
				Add(mspLst, 0);
			else
				Add(mspLst, 1);
			fi;
			# ------------------------------------------------
		        
			# Tomas code
			for k in [1..(j - 1)] do

				i := j - k;

				# Quot1: quotient with translation group to be compared with the 
				# translation group of quotient Quot2
				Quot1 := TGQuotient(conderIndexLst[i]);
				genus1 := TGQuotientGenus(Quot1);

				# check Rieman-Hurwitz formula 
				if IsInt((genus2 - 1)/(genus1 - 1)) and genus2 > genus1 then

					switch2 := 0;
					for l in [(i + 1)..(j - 1)] do
						
						# check if the entry already exists
						if adjMat[i, l] = 1 and adjMat[l, j] = 1 then
							switch2 := 1; 
							adjMat[i, j] := 1;
							break;
						fi;
					od;

					if switch2 = 0 then
						
						# translation group of Quot1
						GAMMA1 := cachedGroup@(toIndex@(Concatenation(signature,conderIndexLst[i])) : tgANDQuot := [tg, Quot1]);

						# check normal subgroup relation
						switch1 := IsSubset(GAMMA1, GAMMA2); # since GAMMA1 is a group IsSubset suffices
						if switch1 = true then
							adjMat[i, j] := 1;
						fi;
					fi;
				fi;
			od;
	 	od;
	 fi;
    
	F := NewFamily( "TGQuotientSequencesAdjacencyMatrix", IsTGQuotientSequencesAdjacencyMatrixObj );
    	return Objectify( NewType( F, IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ), rec(
		signature := MakeImmutable(signature),
		boundByGenus := MakeImmutable(boundByGenus),
		lstTGQuotients := MakeImmutable(conderIndexLst),
		lstMirrorSymmetries := MakeImmutable(mspLst),
		sparse := MakeImmutable(sparse),
		adjMatrix := MakeImmutable(adjMat)
		));

end );

# Takes a matrix and replaces each entry 
# by its sign: +/- 1 for non-zero entries, 0 otherwise.
signMatrix@ := function(mat)
	return List(mat, row -> List(row, entry -> SignInt(entry)));
end;

# Transposes a sparse matrix.
sparseMatTranspose@ := function(matSparse)
	return SortedList(List(matSparse, entry -> [Reversed(entry[1]),entry[2]]));
end;

# Multiplies two sparse matrices. (Not optimized)
sparseMatMultiply@ := function(mat1, mat2)
	local mat2T, matNew, i, j, entry1, entry2, rowIdx, colIdx, temp1, temp2, sum, signed;

	# --------
	# Options:
	# --------		

	# option signed: if signed is true each entry in the 
	# sparse matrix will be replaced by its sign: +/- 1 
	# for non-zero integers 0 otherwise.
    	signed := ValueOption("signed");
    	if signed = fail or signed = false then
    		signed := 0;
    	elif not IsBool(signed) then
		Error(StringFormatted("The option signed {} is not valid. It must be a boolean.", signed));
		return fail;
	else
		signed := 1;
    	fi;

        mat2T := sparseMatTranspose@(mat2); 
	matNew :=  rec(); # new matrix predecessor (will be converted to nested list in the end)
        for i in [1..Length(mat1)] do

	    rowIdx := mat1[i,1][1]; # get row of matrix mat1
            for j in [1..Length(mat2T)] do
		
                colIdx := mat2T[j,1][1]; # corresponds to row of matrix mat2
		if not String([rowIdx, colIdx]) in RecNames(matNew) then

		    temp1 := i;; temp2 := j;; sum := 0;
                    while temp1 <= Length(mat1) and mat1[temp1,1][1] = rowIdx and temp2 <= Length(mat2T) and mat2T[temp2,1][1] = colIdx do
              		
			# multiplication conditions
                        if mat1[temp1,1][2] < mat2T[temp2,1][2] then
                            temp1 := temp1 + 1;
                        elif mat1[temp1,1][2] > mat2T[temp2,1][2] then
 			    temp2 := temp2 + 1;
                        else
			     sum := sum + mat1[temp1,2]*mat2T[temp2,2];; temp1 := temp1 + 1;; temp2 := temp2 + 1;;
                        fi;

			if temp1 > Length(mat1) or temp2 > Length(mat2T) then
				break;
			fi;
 		    od;
                    if not sum = 0 then
			matNew.(String([rowIdx, colIdx])) := sum/AbsoluteValue(sum)^signed ;
		    fi;
		fi;
	    od;
	od;
	# reformat record into a nested list of the form [ [[rowIdx, colIdx], entry], ... ]
	return SortedList(List(RecNames(matNew), item -> [EvalString(item),matNew.(item)]));
end;

# Subtracts sparse matrix mat2 from mat1. (Not optimized)
sparseMatSubtract@ := function(mat1, mat2)
	local idx1, idx2, difference, matNew;

	idx1 := 1;; idx2 := 1;; matNew :=  rec(); # new matrix predecessor (will be converted to nested list in the end)
	while idx1 <= Length(mat1) and idx2 <= Length(mat2) do

		# subtraction conditions for non-empty entries at matching positions in mat1 and mat2
		if mat1[idx1,1][1] > mat2[idx2,1][1] or (mat1[idx1,1][1] = mat2[idx2,1][1] and mat1[idx1,1][2] > mat2[idx2,1][2]) then

			matNew.(String(mat2[idx2,1])) := - mat2[idx2,2];
			idx2 := idx2 + 1;
	
		elif mat1[idx1,1][1] < mat2[idx2,1][1] or (mat1[idx1,1][1] = mat2[idx2,1][1] and mat1[idx1,1][2] < mat2[idx2,1][2])  then

			matNew.(String(mat1[idx1,1])) := mat1[idx1,2];
			idx1 := idx1 + 1;
			
		else
			difference := mat1[idx1,2] - mat2[idx2,2];
			if not difference = 0 then
				matNew.(String(mat1[idx1,1])) := difference;
			fi;
			idx1 := idx1 + 1;
			idx2 := idx2 + 1;
		fi;
	od;

	# if the above conditions are exhausted, trivial subtraction operations for
	# non-empty entries at non-matching positions in mat1 and mat2 are performed
        while idx1 <= Length(mat1) do
        	matNew.(String(mat1[idx1,1])) := mat1[idx1,2];
		idx1 := idx1 + 1;
 	od;

        while idx2 <= Length(mat2) do
		matNew.(String(mat2[idx2,1])) := -mat2[idx2,2];
		idx2 := idx2 + 1;
 	od;
	
	# reformat record into a nested list of the form [ [[rowIdx, colIdx], entry], ... ]
	return SortedList(List(RecNames(matNew), item -> [EvalString(item),matNew.(item)]));
end;


InstallMethod( NearestNeighborAdjacencyMatrix, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	local adjMat, NNadjMat;
	
	# get the adjacency matrix
	adjMat := AdjacencyMatrix(tgQSAdjMat);

	# check for sparsity and subtract the signed matrix 2nd matrix power of adjMat from adjMat
	if IsSparse(tgQSAdjMat) then	
		NNadjMat := sparseMatSubtract@(adjMat,sparseMatMultiply@(adjMat,adjMat : signed := true));
	else 
		NNadjMat := adjMat - signMatrix@(adjMat*adjMat);
	fi;
	return NNadjMat;
end );

# Depth First Search
dfs@ := function(quotient, adjLst, idxLst, visited) 
    local i, newIdxLst, maxIdx;

    visited[quotient] := true; 
    for i in [1..Length(adjLst[quotient])] do 
         
        if not visited[adjLst[quotient][i]] then 
            dfs@(adjLst[quotient][i], adjLst, idxLst, visited);
	fi;
	
	newIdxLst := [];
	Append(newIdxLst, [quotient]);
	Append(newIdxLst, idxLst[adjLst[quotient][i]]);
	maxIdx := PositionMaximum([Length(idxLst[quotient]), Length(newIdxLst)]);
        idxLst[quotient] := [idxLst[quotient], newIdxLst][maxIdx];
   od;
end;


InstallMethod( LongestSequence, [ IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ], 
function(tgQSAdjMat)
	local adjMat, NNadjMat, quotient, lstTGQuotients, sparse, adjLst, idxLst, 
	 visited, N, i, j, entry, mspLst, nonMirrorSymmetric;

	# Needed objects:
	# ---------------

	adjMat := NearestNeighborAdjacencyMatrix(tgQSAdjMat); 
	lstTGQuotients := GetListTGQuotients(tgQSAdjMat); 
	mspLst := MirrorSymmetries(tgQSAdjMat);
	sparse := IsSparse(tgQSAdjMat);
	N := Length(lstTGQuotients);

	# --------
	# Options:
	# --------

	# starting quotient of longest quotient sequence
    	quotient := ValueOption("quotient");
    	if quotient = fail then
    		quotient := 0;
    	elif not (IsPosInt(quotient) or IsList(quotient)) then
        	Error(StringFormatted("Invalid quotient specification: {}", quotient));
        	return fail;
    	fi;

	if IsList(quotient) then
		if not quotient in lstTGQuotients then
			Error(StringFormatted("Quotient {} is not an element in {}.", quotient, lstTGQuotients));
        		return fail;
		else
			quotient := Position(GetListTGQuotients(tgQSAdjMat), quotient);
		fi;
	elif not quotient <= Length(lstTGQuotients) and not quotient = 0 then
		Error(StringFormatted("Quotient {} exceeds the number of elements {} in the list of quotient.", quotient, Length(lstTGQuotients)));
        	return fail;	
	fi;

	# if to include quotient without mirror symmetries
   	nonMirrorSymmetric := ValueOption("nonMirrorSymmetric");
    	if nonMirrorSymmetric = fail or nonMirrorSymmetric = false then
    		nonMirrorSymmetric := false;
    	elif not IsBool(nonMirrorSymmetric) then
        	Error(StringFormatted("The option nonMirrorSymmetric {} is not a boolean.", nonMirrorSymmetric));
        	return fail;
    	fi;

	# if starting quotient has no mirror symmetries but nonMirrorSymmetric is false, i.e., only
	# quotients having mirror symmetries are included, an error will be raised
	if not nonMirrorSymmetric and not quotient = 0 then
		if mspLst[quotient] = 0 then
			Error("This quotinet does not have mirror symmetries.\n");
			Print("Set option nonMirrorSymmetric to true if you want to include quotients without mirror symmetries.");
			return fail;
		fi;
	fi;	

	# -----------------------------
	# Restructure adjacency matrix:
	# -----------------------------
	# Note: the use of SSortedList enables easy removal of list entries in the next code section
	#       when option nonMirrorSymmetric is applied (i.e., ideal for the function RemoveSet)
	
	if not sparse then
		# change dense matrix to a sparse matrix: ordered list of lists
		# each list represents a row, with entries representing a column index of
		# a non-zero entry (all non-zero entries are ones) 
		adjLst := List(adjMat, row -> SSortedList(Positions(row, 1)));
	else
		# as above for dense matrices, i.e., change to another sparse representation 
		adjLst := List([1..N], item -> SSortedList([])); 
		for entry in adjMat do
			Add(adjLst[entry[1,1]], entry[1,2]);
		od;
	fi; 

	# -----------------------------
	# Apply option mirrorSymmetric:
	# -----------------------------

	# TODO: optimize
	if not nonMirrorSymmetric then
		for i in [1..N] do
			for j in [1..N] do
				if mspLst[i] = 0 then
					adjLst[i] := SSortedList([]);
					break;
				elif mspLst[j] = 0 then
					RemoveSet(adjLst[i], j);
				fi;
			od;
		od;
	fi;		

	# -------------------
	# Depth First Search:
	# -------------------

    	idxLst := List([1..N], item -> [item]);
    	visited := List([1..N], item -> false);

    	# Call DFS for every unvisited vertex 
    	for i in [1..N] do
            	if not visited[i] then 
            		dfs@(i, adjLst, idxLst, visited);
		fi;
	od;
	
	if quotient = 0 then
		return lstTGQuotients{idxLst[PositionMaximum(List(idxLst, item -> Length(item)))]};
	else 
		return lstTGQuotients{idxLst[quotient]};
	fi;
end );


InstallMethod( Export, [  IsTGQuotientSequencesAdjacencyMatrixObj, IsOutputTextStream ],
function(tgQSAdjMat, output)

    SetPrintFormattingStatus(output, false);
    
	# version
	AppendTo(output, "HyperCells HCQS version 1.0");
	AppendTo(output, "\n");

    # write: triangle group, genus bound, list of quotients
	AppendTo(output, Signature(tgQSAdjMat));
	AppendTo(output, "\n");
	AppendTo(output, BoundByGenus(tgQSAdjMat));
	AppendTo(output, "\n");
	AppendTo(output, GetListTGQuotients(tgQSAdjMat));
	AppendTo(output, "\n");
	AppendTo(output, MirrorSymmetries(tgQSAdjMat));
	AppendTo(output, "\n");
	AppendTo(output, IsSparse(tgQSAdjMat));
	AppendTo(output, "\n");

    # write: adjacency matrix
	AppendTo(output, AdjacencyMatrix(tgQSAdjMat));
end );

InstallMethod( Export, [ IsTGQuotientSequencesAdjacencyMatrixObj, IsString ],
function(tgQSAdjMat, path)
    local output;

    # open file
    output := OutputTextFile(path, false);

    Export(tgQSAdjMat, output);

    # close file
    CloseStream(output);
end );


InstallMethod( ExportString, [ IsTGQuotientSequencesAdjacencyMatrixObj ],
function(tgQSAdjMat)
	local str, output;

	# open string stream
	str := "";
	output := OutputTextString(str, false);
	
	# export to stream
	Export(tgQSAdjMat, output);

	# close
	CloseStream(output);

	# return
	return str;
end );



InstallGlobalFunction( ImportTGQuotientSequencesAdjacencyMatrix,
function(input)
    local version, signature, boundByGenus, conderIndexLst, mspLst, 
     sparse, adjMat, F;

	# check arguments
	if not IsInputTextStream(input) then
		Error("The first argument must be an input text stream.");
		return fail;
	fi;

	# version
	version := ReadAllLine(input);

    	signature := EvalString(ReadAllLine(input));
	boundByGenus := EvalString(ReadAllLine(input));
	conderIndexLst := EvalString(ReadAllLine(input));
	mspLst := EvalString(ReadAllLine(input));
	sparse := EvalString(ReadAllLine(input));
	adjMat := EvalString(ReadAllLine(input));
	

	F := NewFamily( "TGQuotientSequencesAdjacencyMatrix", IsTGQuotientSequencesAdjacencyMatrixObj );
    	return Objectify( NewType( F, IsTGQuotientSequencesAdjacencyMatrixObj and IsTGQuotientSequencesAdjacencyMatrixComponentRep ), rec(
		signature := MakeImmutable(signature),
		boundByGenus := MakeImmutable(boundByGenus),
		lstTGQuotients := MakeImmutable(conderIndexLst),
		lstMirrorSymmetries := MakeImmutable(mspLst),
		sparse := MakeImmutable(sparse),
		adjMatrix := MakeImmutable(adjMat)
	));
end );


InstallGlobalFunction( ImportTGQuotientSequencesAdjacencyMatrixFromFile,
function(path)
	local input, tgQSAdjMat;

	# open input stream
	input := InputTextFile(path);

	# import
	tgQSAdjMat := CallFuncList(ImportTGQuotientSequencesAdjacencyMatrix, [input]);

	# close stream
	CloseStream(input);

	return tgQSAdjMat;
end );


InstallGlobalFunction( ImportTGQuotientSequencesAdjacencyMatrixFromString,
function(string)
	local input, tgQSAdjMat;

	# check arguments
	if not IsString(string) then
		Error("The first argument must be a string.");
		return fail;
	fi;

	# open string stream
	input := InputTextString(string);
	
	# import
	tgQSAdjMat := CallFuncList(ImportTGQuotientSequencesAdjacencyMatrix, [input]);

	# close stream
	CloseStream(input);

	return tgQSAdjMat;
end );


