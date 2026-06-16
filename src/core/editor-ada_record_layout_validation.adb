with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Record_Layout_Validation is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Abs_Natural (Value : Long_Long_Integer) return Natural is
   begin
      if Value < 0 then
         return Natural ((-Value) mod 2_147_483_647);
      else
         return Natural (Value mod 2_147_483_647);
      end if;
   end Abs_Natural;

   procedure Clear (Model : in out Record_Layout_Model) is
   begin
      Model.Checks.Clear;
      Model.Overlap_Total := 0;
      Model.Valid_Span_Total := 0;
      Model.Static_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Size_Exceeded_Total := 0;
      Model.Alignment_Warning_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Overlaps
     (Left_Start  : Long_Long_Integer;
      Left_End    : Long_Long_Integer;
      Right_Start : Long_Long_Integer;
      Right_End   : Long_Long_Integer) return Boolean is
   begin
      return Left_Start <= Right_End and then Right_Start <= Left_End;
   end Overlaps;

   function Prior_Overlap
     (Model         : Record_Layout_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Start_Bit     : Long_Long_Integer;
      End_Bit       : Long_Long_Integer) return Record_Layout_Info is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Prior : constant Record_Layout_Info := Model.Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then Prior.Status = Record_Layout_Ok
              and then Overlaps (Start_Bit, End_Bit, Prior.Start_Bit, Prior.End_Bit)
            then
               return Prior;
            end if;
         end;
      end loop;
      return (others => <>);
   end Prior_Overlap;

   procedure Count_Result
     (Model : in out Record_Layout_Model;
      Info  : Record_Layout_Info) is
   begin
      case Info.Status is
         when Record_Layout_Ok =>
            Model.Valid_Span_Total := Model.Valid_Span_Total + 1;
         when Record_Layout_Overlap =>
            Model.Overlap_Total := Model.Overlap_Total + 1;
         when Record_Layout_Static_Error =>
            Model.Static_Error_Total := Model.Static_Error_Total + 1;
         when Record_Layout_Component_Error =>
            Model.Component_Error_Total := Model.Component_Error_Total + 1;
         when Record_Layout_Size_Exceeded =>
            Model.Size_Exceeded_Total := Model.Size_Exceeded_Total + 1;
         when Record_Layout_Alignment_Warning =>
            Model.Alignment_Warning_Total := Model.Alignment_Warning_Total + 1;
         when Record_Layout_Unknown =>
            null;
      end case;
   end Count_Result;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model)
      return Record_Layout_Model is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      Result : Record_Layout_Model;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Record_Component_Check_Count (Legality) loop
         declare
            Component : constant Editor.Ada_Representation_Legality.Record_Component_Legality_Info :=
              Editor.Ada_Representation_Legality.Record_Component_Check_At (Legality, Index);
            Info : Record_Layout_Info;
            Prior : Record_Layout_Info;
         begin
            Info.Component_Node := Component.Clause_Node;
            Info.Parent_Clause := Component.Parent_Clause;
            Info.Target_Name := Component.Target_Name;
            Info.Component_Name := Component.Component_Name;
            Info.Source_Line := Component.Source_Line;

            if Component.Status in
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Static_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Bit_Range_Reversed |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Negative_Position
            then
               Info.Status := Record_Layout_Static_Error;
            elsif Component.Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok then
               Info.Status := Record_Layout_Component_Error;
            else
               Info.Start_Bit := Component.Static_Storage_Unit * 8 + Component.Static_First_Bit;
               Info.End_Bit := Component.Static_Storage_Unit * 8 + Component.Static_Last_Bit;
               Prior := Prior_Overlap (Result, Info.Parent_Clause, Info.Start_Bit, Info.End_Bit);
               if Prior.Component_Node /= Editor.Ada_Syntax_Tree.No_Node then
                  Info.Status := Record_Layout_Overlap;
                  Info.Overlap_Component := Prior.Component_Name;
                  Info.Overlap_Node := Prior.Component_Node;
               else
                  Info.Status := Record_Layout_Ok;
               end if;
            end if;

            Info.Fingerprint :=
              Mix (Natural (Info.Component_Node),
                   Mix (Natural (Info.Parent_Clause),
                        Mix (Info.Source_Line,
                             Mix (Record_Layout_Status'Pos (Info.Status),
                                  Mix (Abs_Natural (Info.Start_Bit),
                                       Abs_Natural (Info.End_Bit))))));

            Result.Checks.Append (Info);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Info.Fingerprint);
            Count_Result (Result, Info);
         end;
      end loop;

      return Result;
   end Build;

   function Check_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Record_Layout_Model;
      Index : Positive) return Record_Layout_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Overlap_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Overlap_Total;
   end Overlap_Count;

   function Valid_Span_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Valid_Span_Total;
   end Valid_Span_Count;

   function Static_Error_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Static_Error_Total;
   end Static_Error_Count;

   function Component_Error_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Component_Error_Total;
   end Component_Error_Count;

   function Size_Exceeded_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Size_Exceeded_Total;
   end Size_Exceeded_Count;

   function Alignment_Warning_Count (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Alignment_Warning_Total;
   end Alignment_Warning_Count;

   function Fingerprint (Model : Record_Layout_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Record_Layout_Validation;
