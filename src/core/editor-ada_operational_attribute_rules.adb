with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Operational_Attribute_Rules is

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalize;

   function Is_Operational_Property
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   begin
      return Kind in
        Editor.Ada_Language_Model.Representation_Pack_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Clause |
        Editor.Ada_Language_Model.Representation_Independent_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
        Editor.Ada_Language_Model.Representation_Independent_Components_Clause |
        Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause |
        Editor.Ada_Language_Model.Representation_Unchecked_Union_Clause |
        Editor.Ada_Language_Model.Representation_Discard_Names_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Full_Access_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Always_Lock_Free_Clause;
   end Is_Operational_Property;

   function Bool_Value
     (Status : Editor.Ada_Representation_Legality.Operational_Value_Status)
      return Operational_Boolean_Value is
      use type Editor.Ada_Representation_Legality.Operational_Value_Status;
   begin
      if Status = Editor.Ada_Representation_Legality.Operational_Value_Static_Boolean_True then
         return Operational_Boolean_True;
      elsif Status = Editor.Ada_Representation_Legality.Operational_Value_Static_Boolean_False then
         return Operational_Boolean_False;
      elsif Status = Editor.Ada_Representation_Legality.Operational_Value_Not_Operational_Clause then
         return Operational_Boolean_None;
      elsif Status = Editor.Ada_Representation_Legality.Operational_Value_Malformed then
         return Operational_Boolean_Unknown;
      else
         return Operational_Boolean_Unknown;
      end if;
   end Bool_Value;

   function Is_Target_Error
     (Status : Editor.Ada_Representation_Legality.Representation_Legality_Status)
      return Boolean is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
   begin
      return Status = Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible;
   end Is_Target_Error;

   function Is_Value_Error
     (Status : Editor.Ada_Representation_Legality.Representation_Legality_Status)
      return Boolean is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
   begin
      return Status = Editor.Ada_Representation_Legality.Representation_Legality_Operational_Boolean_Value_Required;
   end Is_Value_Error;

   procedure Clear (Model : in out Operational_Rule_Model) is
   begin
      Model.Rules.Clear;
      Model.Duplicate_Total := 0;
      Model.Conflict_Total := 0;
      Model.Target_Error_Total := 0;
      Model.Value_Error_Total := 0;
      Model.Ok_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Count_Result
     (Model : in out Operational_Rule_Model;
      Info  : Operational_Rule_Info) is
   begin
      case Info.Status is
         when Operational_Rule_Duplicate_Property =>
            Model.Duplicate_Total := Model.Duplicate_Total + 1;
         when Operational_Rule_Conflicting_Boolean_Value =>
            Model.Conflict_Total := Model.Conflict_Total + 1;
         when Operational_Rule_Target_Error =>
            Model.Target_Error_Total := Model.Target_Error_Total + 1;
         when Operational_Rule_Value_Error =>
            Model.Value_Error_Total := Model.Value_Error_Total + 1;
         when Operational_Rule_Ok =>
            Model.Ok_Total := Model.Ok_Total + 1;
         when Operational_Rule_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
      end case;
   end Count_Result;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model)
      return Operational_Rule_Model is
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Result : Operational_Rule_Model;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Check : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
            Rule : Operational_Rule_Info;
         begin
            if Is_Operational_Property (Check.Clause_Kind) then
               Rule.Clause_Node := Check.Clause_Node;
               Rule.Target_Name := Check.Target_Name;
               Rule.Normalized_Target := Normalize (Check.Target_Name);
               Rule.Clause_Kind := Check.Clause_Kind;
               Rule.Source_Form := Check.Source_Form;
               Rule.Boolean_Value := Bool_Value (Check.Operational_Status);
               Rule.Source_Line := Check.Source_Line;

               if Is_Target_Error (Check.Status) then
                  Rule.Status := Operational_Rule_Target_Error;
               elsif Is_Value_Error (Check.Status)
                 or else Rule.Boolean_Value = Operational_Boolean_Unknown
               then
                  Rule.Status := Operational_Rule_Value_Error;
               else
                  Rule.Status := Operational_Rule_Ok;

                  for Previous_Index in 1 .. Result.Rules.Last_Index loop
                     declare
                        Previous : constant Operational_Rule_Info := Result.Rules (Previous_Index);
                     begin
                        if Previous.Normalized_Target = Rule.Normalized_Target
                          and then Previous.Clause_Kind = Rule.Clause_Kind
                        then
                           Rule.Previous_Clause := Previous.Clause_Node;
                           Rule.Previous_Value := Previous.Boolean_Value;

                           if Previous.Boolean_Value in Operational_Boolean_True | Operational_Boolean_False
                             and then Rule.Boolean_Value in Operational_Boolean_True | Operational_Boolean_False
                             and then Previous.Boolean_Value /= Rule.Boolean_Value
                           then
                              Rule.Status := Operational_Rule_Conflicting_Boolean_Value;
                           else
                              Rule.Status := Operational_Rule_Duplicate_Property;
                           end if;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;

               Rule.Fingerprint :=
                 Mix (Natural (Rule.Clause_Node),
                      Mix (Rule.Source_Line,
                           Mix (Editor.Ada_Language_Model.Representation_Clause_Kind'Pos (Rule.Clause_Kind),
                                Mix (Operational_Boolean_Value'Pos (Rule.Boolean_Value),
                                     Operational_Rule_Status'Pos (Rule.Status)))));

               Result.Rules.Append (Rule);
               Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Rule.Fingerprint);
               Count_Result (Result, Rule);
            end if;
         end;
      end loop;

      return Result;
   end Build;

   function Rule_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Natural (Model.Rules.Length);
   end Rule_Count;

   function Rule_At
     (Model : Operational_Rule_Model;
      Index : Positive) return Operational_Rule_Info is
   begin
      return Model.Rules (Index);
   end Rule_At;

   function Duplicate_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Duplicate_Total;
   end Duplicate_Count;

   function Conflict_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Conflict_Total;
   end Conflict_Count;

   function Target_Error_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Target_Error_Total;
   end Target_Error_Count;

   function Value_Error_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Value_Error_Total;
   end Value_Error_Count;

   function Ok_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Ok_Total;
   end Ok_Count;

   function Unknown_Count (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Operational_Rule_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Operational_Attribute_Rules;
