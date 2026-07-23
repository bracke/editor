with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
with Editor.Ada_Expression_Types.Access_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Call_Inference;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Model_Accessors;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;

separate (Editor.Ada_Expression_Types)
   procedure Apply_Operator_Overload_Resolution
     (Regions        : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility     : Editor.Ada_Direct_Visibility.Visibility_Model;
      Primitives     : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Info           : in out Expression_Type_Info;
      Use_Primitives : Boolean)
   is
      Symbol : constant String := To_String (Info.Operator_Symbol);
      NL     : constant String := To_String (Info.Normalized_Left_Operand_Subtype);
      NR     : constant String := To_String (Info.Normalized_Right_Operand_Subtype);
      Direct : Editor.Ada_Direct_Visibility.Lookup_Result :=
        (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
         Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
         Region => Info.Region,
         Match_Count => 0);
      Direct_Quoted : Editor.Ada_Direct_Visibility.Lookup_Result := Direct;
      Primitive : Editor.Ada_Direct_Visibility.Lookup_Result := Direct;
      Candidate_Count : Natural := 0;
      Primitive_Selected : Natural := 0;
      Primitive_Mismatched : Natural := 0;
      Operand_Known : constant Boolean := NL /= "" and then
        (NR /= "" or else Symbol = "+" or else Symbol = "-" or else Symbol = "not" or else Symbol = "abs");
   begin
      if Symbol = "" then
         return;
      end if;

      Direct := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, Info.Region, Symbol);
      if Direct.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         Direct_Quoted := Editor.Ada_Direct_Visibility.Lookup_Visible
           (Visibility, Regions, Info.Region, '"' & Symbol & '"');
      end if;

      if Use_Primitives then
         Primitive := Editor.Ada_Use_Type_Operators.Lookup_Operator
           (Primitives, Info.Region, Symbol);
      end if;

      Candidate_Count := Direct.Match_Count + Direct_Quoted.Match_Count + Primitive.Match_Count;
      if Candidate_Count = 0 and then Use_Primitives then
         for I in 1 .. Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitives) loop
            declare
               P : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Info :=
                 Editor.Ada_Use_Type_Operators.Primitive_Use_At (Primitives, I);
            begin
               if P.Status = Editor.Ada_Use_Type_Operators.Primitive_Use_Found
                 and then P.Is_Operator
                 and then To_String (P.Normalized_Primitive) = Normalize (Symbol)
               then
                  Candidate_Count := Candidate_Count + 1;
               end if;
            end;
         end loop;
      end if;
      Info.Operator_Overload_Candidate_Count := Candidate_Count;

      if Candidate_Count = 0 then
         return;
      end if;

      if Use_Primitives then
         for I in 1 .. Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitives) loop
            declare
               P : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Info :=
                 Editor.Ada_Use_Type_Operators.Primitive_Use_At (Primitives, I);
               PT : constant String := To_String (P.Normalized_Type_Name);
            begin
               if P.Status = Editor.Ada_Use_Type_Operators.Primitive_Use_Found
                 and then P.Is_Operator
                 and then To_String (P.Normalized_Primitive) = Normalize (Symbol)
               then
                  if Operand_Known and then
                    (NL = PT or else NR = PT or else
                     (Is_Numeric_Family (NL) and then Is_Numeric_Family (PT)) or else
                     (Is_Numeric_Family (NR) and then Is_Numeric_Family (PT)))
                  then
                     Primitive_Selected := Primitive_Selected + 1;
                  elsif Operand_Known then
                     Primitive_Mismatched := Primitive_Mismatched + 1;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Primitive_Selected = 1 and then Direct.Match_Count = 0 and then Direct_Quoted.Match_Count = 0 then
         Info.Operator_Status := Operator_Type_Overload_Resolved;
         Info.Operator_Overload_Selected_Count := 1;
         Info.Operator_Compatible_Operand_Count := Natural'Max (Info.Operator_Compatible_Operand_Count, (if NR /= "" then 2 else 1));
         if Is_Relational_Operator (Symbol) or else Is_Boolean_Operator (Symbol) then
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
         elsif NL /= "" then
            Info.Status := Expression_Type_Operator_Numeric;
            Info.Operator_Result_Subtype := Info.Left_Operand_Subtype;
            Info.Normalized_Operator_Result_Subtype := Info.Normalized_Left_Operand_Subtype;
         else
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
         Info.Inferred_Subtype := Info.Operator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
      elsif Primitive_Selected > 1 or else Candidate_Count > 1 then
         Info.Operator_Status := Operator_Type_Overload_Ambiguous;
         Info.Operator_Overload_Ambiguous_Count := Candidate_Count;
         Info.Candidate_Count := Natural'Max (Info.Candidate_Count, Candidate_Count);
      elsif Primitive_Mismatched > 0 and then Primitive_Selected = 0 and then
        Direct.Match_Count = 0 and then Direct_Quoted.Match_Count = 0
      then
         Info.Operator_Status := Operator_Type_Overload_Mismatch;
         Info.Operator_Overload_Mismatch_Count := Primitive_Mismatched;
         Info.Operator_Mismatched_Operand_Count := Natural'Max (Info.Operator_Mismatched_Operand_Count, 1);
         Info.Status := Expression_Type_Operator_Unknown;
      elsif not Operand_Known then
         Info.Operator_Status := Operator_Type_Overload_Unknown;
         Info.Operator_Unknown_Operand_Count := Natural'Max (Info.Operator_Unknown_Operand_Count, 1);
      elsif Candidate_Count = 1 and then (Direct.Match_Count = 1 or else Direct_Quoted.Match_Count = 1) then
         Info.Operator_Status := Operator_Type_Overload_Unknown;
         Info.Operator_Overload_Selected_Count := 1;
      end if;
   end Apply_Operator_Overload_Resolution;
