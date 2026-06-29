with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility is

   pragma Suppress (Overflow_Check);

   package AX renames Editor.Ada_Accessibility_Lifetime_Legality;
   use type AX.Accessibility_Legality_Status;

   function Mix (Left, Right : Natural) return Natural is
      Modulus : constant Long_Long_Integer := 2_147_483_647;
      L : constant Long_Long_Integer :=
        Long_Long_Integer (Left mod Natural (Modulus));
      R : constant Long_Long_Integer :=
        Long_Long_Integer (Right mod Natural (Modulus));
      Hash : constant Long_Long_Integer :=
        (L * 1_315_423_911 + R * 2_654_435_761 + 197) mod Modulus;
   begin
      return Natural (Hash);
   end Mix;

   function Severity_For_Unresolved
     (Unresolved : Boolean) return Wide_Semantic_Diagnostic_Severity is
   begin
      if Unresolved then
         return Wide_Semantic_Diagnostic_Warning;
      else
         return Wide_Semantic_Diagnostic_Error;
      end if;
   end Severity_For_Unresolved;

   function Is_Accessibility_Legal
     (Status : AX.Accessibility_Legality_Status) return Boolean is
   begin
      return Status in AX.Accessibility_Legality_Static_Compatible |
        AX.Accessibility_Legality_Dynamic_Check_Required |
        AX.Accessibility_Legality_Null_Exclusion_Checked |
        AX.Accessibility_Legality_Aliased_Object_Compatible |
        AX.Accessibility_Legality_Allocator_Compatible |
        AX.Accessibility_Legality_Access_Conversion_Compatible |
        AX.Accessibility_Legality_Return_Access_Compatible;
   end Is_Accessibility_Legal;

   function Is_Expression_Duplicate
     (Status : AX.Accessibility_Legality_Status) return Boolean is
   begin
      return Status in AX.Accessibility_Legality_Null_Exclusion_Violation |
        AX.Accessibility_Legality_Access_Kind_Mismatch |
        AX.Accessibility_Legality_Allocator_Designated_Subtype_Mismatch |
        AX.Accessibility_Legality_Linked_Semantic_Error;
   end Is_Expression_Duplicate;

   function Kind_For_Accessibility (Status : AX.Accessibility_Legality_Status)
      return Wide_Semantic_Diagnostic_Kind is
   begin
      if Status in AX.Accessibility_Legality_Private_View_Barrier |
        AX.Accessibility_Legality_Limited_View_Barrier then
         return Wide_Semantic_Diagnostic_View_Barrier;
      elsif Status in AX.Accessibility_Legality_Cross_Unit_Unresolved_View |
        AX.Accessibility_Legality_Anonymous_Access_Level_Unresolved then
         return Wide_Semantic_Diagnostic_Unresolved_Semantic_State;
      elsif Status = AX.Accessibility_Legality_Indeterminate then
         return Wide_Semantic_Diagnostic_Indeterminate_State;
      else
         return Wide_Semantic_Diagnostic_Accessibility_Lifetime_Error;
      end if;
   end Kind_For_Accessibility;

   function Diagnostic_Fingerprint
     (Info   : Wide_Semantic_Diagnostic_Info;
      Status : AX.Accessibility_Legality_Status) return Natural
   is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Wide_Semantic_Diagnostic_Family'Pos (Info.Family) + 1);
      H := Mix (H, Wide_Semantic_Diagnostic_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Wide_Semantic_Diagnostic_Severity'Pos (Info.Severity) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, AX.Accessibility_Legality_Status'Pos (Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Diagnostic_Fingerprint;

   procedure Append
     (Model  : in out Wide_Semantic_Diagnostic_Model;
      Info   : in out Wide_Semantic_Diagnostic_Info;
      Status : AX.Accessibility_Legality_Status)
   is
   begin
      Info.Id := Wide_Semantic_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Fingerprint := Diagnostic_Fingerprint (Info, Status);
      Model.Diagnostics.Append (Info);
      case Info.Severity is
         when Wide_Semantic_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Wide_Semantic_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Wide_Semantic_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint + 1);
   end Append;

   function Build_With_Accessibility
     (Assignments : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model;
      Accessibility : AX.Accessibility_Legality_Model)
      return Wide_Semantic_Diagnostic_Model
   is
      Model : Wide_Semantic_Diagnostic_Model :=
        Build
          (Assignments, Returns, Expressions, Flow, Tasking, Tagged_Model,
           Instances, Cross_Unit);
   begin
      for I in 1 .. AX.Legality_Count (Accessibility) loop
         declare
            A : constant AX.Accessibility_Legality_Info :=
              AX.Legality_At (Accessibility, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if A.Status /= AX.Accessibility_Legality_Not_Checked
              and then not Is_Accessibility_Legal (A.Status)
              and then not Is_Expression_Duplicate (A.Status)
            then
               D.Family := Wide_Semantic_Diagnostic_Accessibility_Lifetime;
               D.Kind := Kind_For_Accessibility (A.Status);
               D.Severity :=
                 Severity_For_Unresolved
                   (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := A.Node;
               D.Message := A.Message;
               D.Detail := A.Detail;
               D.Start_Line := A.Start_Line;
               D.Start_Column := A.Start_Column;
               D.End_Line := A.End_Line;
               D.End_Column := A.End_Column;
               D.Source_Fingerprint := A.Fingerprint;
               Append (Model, D, A.Status);
            end if;
         end;
      end loop;
      return Model;
   end Build_With_Accessibility;

end Editor.Ada_Wide_Semantic_Legality_Diagnostics.Accessibility;
