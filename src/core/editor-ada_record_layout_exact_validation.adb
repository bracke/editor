with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Record_Layout_Exact_Validation is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Record_Layout_Validation.Record_Layout_Status;

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

   function Normalize (Name : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Name);
   end Normalize;

   function Is_Power_Of_Two (Value : Long_Long_Integer) return Boolean is
      Work : Long_Long_Integer := Value;
   begin
      if Work <= 0 then
         return False;
      end if;
      while Work mod 2 = 0 loop
         Work := Work / 2;
      end loop;
      return Work = 1;
   end Is_Power_Of_Two;

   procedure Clear (Model : in out Exact_Record_Layout_Model) is
   begin
      Model.Checks.Clear;
      Model.Status_Counts := (others => 0);
      Model.Ok_Total := 0;
      Model.Size_Exact_Total := 0;
      Model.Size_Padded_Total := 0;
      Model.Size_Exceeded_Total := 0;
      Model.Alignment_Compatible_Total := 0;
      Model.Alignment_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Count_Result
     (Model : in out Exact_Record_Layout_Model;
      Info  : Exact_Record_Layout_Info) is
   begin
      Model.Status_Counts (Info.Status) := Model.Status_Counts (Info.Status) + 1;
      case Info.Status is
         when Exact_Record_Layout_Ok =>
            Model.Ok_Total := Model.Ok_Total + 1;
         when Exact_Record_Layout_Size_Clause_Exact =>
            Model.Size_Exact_Total := Model.Size_Exact_Total + 1;
         when Exact_Record_Layout_Size_Clause_Padded =>
            Model.Size_Padded_Total := Model.Size_Padded_Total + 1;
         when Exact_Record_Layout_Size_Clause_Exceeded =>
            Model.Size_Exceeded_Total := Model.Size_Exceeded_Total + 1;
         when Exact_Record_Layout_Alignment_Compatible =>
            Model.Alignment_Compatible_Total := Model.Alignment_Compatible_Total + 1;
         when Exact_Record_Layout_Alignment_Not_Power_Of_Two |
              Exact_Record_Layout_Alignment_Static_Error |
              Exact_Record_Layout_Alignment_Target_Error =>
            Model.Alignment_Error_Total := Model.Alignment_Error_Total + 1;
         when Exact_Record_Layout_Component_Error =>
            Model.Component_Error_Total := Model.Component_Error_Total + 1;
         when Exact_Record_Layout_Unknown =>
            null;
      end case;
   end Count_Result;

   function Existing_Target_Index
     (Model  : Exact_Record_Layout_Model;
      Target : String) return Natural is
      Normalized : constant String := Normalize (Target);
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         if To_String (Model.Checks (Index).Normalized_Target) = Normalized then
            return Index;
         end if;
      end loop;
      return 0;
   end Existing_Target_Index;

   procedure Add_Component_Summary
     (Model : in out Exact_Record_Layout_Model;
      Info  : Editor.Ada_Record_Layout_Validation.Record_Layout_Info) is
      Target : constant String := To_String (Info.Target_Name);
      Existing : constant Natural := Existing_Target_Index (Model, Target);
      Required : constant Long_Long_Integer := Info.End_Bit + 1;
      Summary : Exact_Record_Layout_Info;
   begin
      if Existing = 0 then
         Summary.Target_Name := Info.Target_Name;
         Summary.Normalized_Target := To_Unbounded_String (Normalize (Target));
         Summary.Clause_Node := Info.Parent_Clause;
         Summary.Source_Line := Info.Source_Line;
         Summary.Required_Bits := Required;
         Summary.Component_Count := 1;
         Summary.Layout_Fingerprint := Info.Fingerprint;
         if Info.Status = Editor.Ada_Record_Layout_Validation.Record_Layout_Ok then
            Summary.Status := Exact_Record_Layout_Ok;
         else
            Summary.Status := Exact_Record_Layout_Component_Error;
         end if;
         Summary.Fingerprint :=
           Mix (Natural (Summary.Clause_Node),
                Mix (Summary.Source_Line,
                     Mix (Abs_Natural (Summary.Required_Bits),
                          Exact_Record_Layout_Status'Pos (Summary.Status))));
         Model.Checks.Append (Summary);
      else
         Summary := Model.Checks (Positive (Existing));
         Summary.Required_Bits := Long_Long_Integer'Max (Summary.Required_Bits, Required);
         Summary.Component_Count := Summary.Component_Count + 1;
         Summary.Layout_Fingerprint := Mix (Summary.Layout_Fingerprint, Info.Fingerprint);
         if Info.Status /= Editor.Ada_Record_Layout_Validation.Record_Layout_Ok then
            Summary.Status := Exact_Record_Layout_Component_Error;
         end if;
         Summary.Fingerprint :=
           Mix (Natural (Summary.Clause_Node),
                Mix (Summary.Source_Line,
                     Mix (Abs_Natural (Summary.Required_Bits),
                          Mix (Summary.Component_Count,
                               Exact_Record_Layout_Status'Pos (Summary.Status)))));
         Model.Checks.Replace_Element (Positive (Existing), Summary);
      end if;
   end Add_Component_Summary;

   procedure Append_Check
     (Model : in out Exact_Record_Layout_Model;
      Info  : Exact_Record_Layout_Info) is
      Item : Exact_Record_Layout_Info := Info;
   begin
      Item.Fingerprint :=
        Mix (Natural (Item.Clause_Node),
             Mix (Item.Source_Line,
                  Mix (Abs_Natural (Item.Required_Bits),
                       Mix (Abs_Natural (Item.Declared_Size_Bits),
                            Mix (Abs_Natural (Item.Declared_Alignment),
                                 Mix (Item.Component_Count,
                                      Mix (Item.Layout_Fingerprint,
                                           Mix (Item.Clause_Fingerprint,
                                                Exact_Record_Layout_Status'Pos (Item.Status)))))))));
      Model.Checks.Append (Item);
      Count_Result (Model, Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Append_Check;

   function Find_Summary
     (Model  : Exact_Record_Layout_Model;
      Target : String) return Exact_Record_Layout_Info is
      Normalized : constant String := Normalize (Target);
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : constant Exact_Record_Layout_Info := Model.Checks (Index);
         begin
            if To_String (Info.Normalized_Target) = Normalized
              and then Info.Declared_Size_Bits = 0
              and then Info.Declared_Alignment = 0
            then
               return Info;
            end if;
         end;
      end loop;
      return (others => <>);
   end Find_Summary;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout   : Editor.Ada_Record_Layout_Validation.Record_Layout_Model)
      return Exact_Record_Layout_Model is
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Representation_Value_Status;
      Summaries : Exact_Record_Layout_Model;
      Result    : Exact_Record_Layout_Model;
   begin
      for Index in 1 .. Editor.Ada_Record_Layout_Validation.Check_Count (Layout) loop
         Add_Component_Summary
           (Summaries, Editor.Ada_Record_Layout_Validation.Check_At (Layout, Index));
      end loop;

      for Index in 1 .. Natural (Summaries.Checks.Length) loop
         declare
            Summary : constant Exact_Record_Layout_Info := Summaries.Checks (Index);
         begin
            Append_Check (Result, Summary);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Clause : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
            Summary : constant Exact_Record_Layout_Info := Find_Summary (Summaries, To_String (Clause.Target_Name));
            Info : Exact_Record_Layout_Info;
         begin
            if Clause.Clause_Kind = Editor.Ada_Language_Model.Representation_Size_Clause
              and then Summary.Component_Count > 0
            then
               Info := Summary;
               Info.Clause_Node := Clause.Clause_Node;
               Info.Source_Line := Clause.Source_Line;
               Info.Declared_Size_Bits := Clause.Static_Integer;
               Info.Clause_Fingerprint := Clause.Fingerprint;
               if Clause.Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok
                 or else Clause.Value_Status /= Editor.Ada_Representation_Legality.Representation_Value_Static_Integer
               then
                  Info.Status := Exact_Record_Layout_Component_Error;
               elsif Clause.Static_Integer < Summary.Required_Bits then
                  Info.Status := Exact_Record_Layout_Size_Clause_Exceeded;
               elsif Clause.Static_Integer = Summary.Required_Bits then
                  Info.Status := Exact_Record_Layout_Size_Clause_Exact;
               else
                  Info.Status := Exact_Record_Layout_Size_Clause_Padded;
               end if;
               Append_Check (Result, Info);
            elsif Clause.Clause_Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
              and then Summary.Component_Count > 0
            then
               Info := Summary;
               Info.Clause_Node := Clause.Clause_Node;
               Info.Source_Line := Clause.Source_Line;
               Info.Declared_Alignment := Clause.Static_Integer;
               Info.Clause_Fingerprint := Clause.Fingerprint;
               if Clause.Status = Editor.Ada_Representation_Legality.Representation_Legality_Alignment_Target_Incompatible then
                  Info.Status := Exact_Record_Layout_Alignment_Target_Error;
               elsif Clause.Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok
                 or else Clause.Value_Status /= Editor.Ada_Representation_Legality.Representation_Value_Static_Integer
               then
                  Info.Status := Exact_Record_Layout_Alignment_Static_Error;
               elsif not Is_Power_Of_Two (Clause.Static_Integer) then
                  Info.Status := Exact_Record_Layout_Alignment_Not_Power_Of_Two;
               else
                  Info.Status := Exact_Record_Layout_Alignment_Compatible;
               end if;
               Append_Check (Result, Info);
            end if;
         end;
      end loop;

      return Result;
   end Build;

   function Check_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Exact_Record_Layout_Model;
      Index : Positive) return Exact_Record_Layout_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function First_For_Target
     (Model  : Exact_Record_Layout_Model;
      Target : String) return Exact_Record_Layout_Info is
      Normalized : constant String := Normalize (Target);
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         if To_String (Model.Checks (Index).Normalized_Target) = Normalized then
            return Model.Checks (Index);
         end if;
      end loop;
      return (others => <>);
   end First_For_Target;

   function Count_Status
     (Model  : Exact_Record_Layout_Model;
      Status : Exact_Record_Layout_Status) return Natural is
   begin
      return Model.Status_Counts (Status);
   end Count_Status;

   function Ok_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Ok_Total;
   end Ok_Count;

   function Size_Exact_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Size_Exact_Total;
   end Size_Exact_Count;

   function Size_Padded_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Size_Padded_Total;
   end Size_Padded_Count;

   function Size_Exceeded_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Size_Exceeded_Total;
   end Size_Exceeded_Count;

   function Alignment_Compatible_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Alignment_Compatible_Total;
   end Alignment_Compatible_Count;

   function Alignment_Error_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Alignment_Error_Total;
   end Alignment_Error_Count;

   function Component_Error_Count (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Component_Error_Total;
   end Component_Error_Count;

   function Fingerprint (Model : Exact_Record_Layout_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Record_Layout_Exact_Validation;
