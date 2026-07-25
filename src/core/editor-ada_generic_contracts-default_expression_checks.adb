separate (Editor.Ada_Generic_Contracts)
package body Default_Expression_Checks is

   procedure Classify_Object_Expression
     (Info       : in out Generic_Actual_Match_Info;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) is
      Value : Editor.Ada_Static_Expressions.Static_Value_Info;
   begin
      Info.Default_Expression_Checked_Formals :=
        Info.Default_Expression_Checked_Formals + 1;
      if Trim (Expression) = "" then
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
         return;
      end if;

      Value := Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
        (Static, Region, Expression);
      if Editor.Ada_Static_Expressions.Is_Static_Numeric (Value)
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Static_Attribute
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Integer
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Point
      then
         Info.Default_Expression_Static_Formals :=
           Info.Default_Expression_Static_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name then
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
         Info.Default_Expression_Unresolved_Formals :=
           Info.Default_Expression_Unresolved_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Non_Static then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Nonstatic_Formals :=
           Info.Default_Expression_Nonstatic_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Malformed then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Malformed_Formals :=
           Info.Default_Expression_Malformed_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Division_By_Zero_Formals :=
           Info.Default_Expression_Division_By_Zero_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unsupported_Attribute
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Delta_Mismatch
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Range_Error
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Overflow
      then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
      else
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
      end if;
   end Classify_Object_Expression;


end Default_Expression_Checks;
