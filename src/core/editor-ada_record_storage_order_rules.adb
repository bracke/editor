with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Record_Storage_Order_Rules is

   pragma Suppress (Overflow_Check);

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Text : Unbounded_String) return String is
      S    : constant String := To_String (Text);
      Tick : Natural := 0;
   begin
      for I in S'Range loop
         if Character'Pos (S (I)) = 39 then
            Tick := I;
            exit;
         end if;
      end loop;

      if Tick /= 0 and then Tick > S'First then
         return Ada.Characters.Handling.To_Lower (S (S'First .. Tick - 1));
      else
         return Ada.Characters.Handling.To_Lower (S);
      end if;
   end Normalize;

   function Order_For
     (Status : Editor.Ada_Representation_Legality.Operational_Value_Status)
      return Storage_Order_Value is
      use type Editor.Ada_Representation_Legality.Operational_Value_Status;
   begin
      if Status = Editor.Ada_Representation_Legality.Operational_Value_Order_High_Order_First then
         return Storage_Order_High_Order_First;
      elsif Status = Editor.Ada_Representation_Legality.Operational_Value_Order_Low_Order_First then
         return Storage_Order_Low_Order_First;
      elsif Status = Editor.Ada_Representation_Legality.Operational_Value_Not_Operational_Clause then
         return Storage_Order_None;
      else
         return Storage_Order_Unknown;
      end if;
   end Order_For;

   function Is_Operational_Error
     (Info : Editor.Ada_Representation_Legality.Representation_Legality_Info)
      return Boolean is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
   begin
      return Info.Status in
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible |
        Editor.Ada_Representation_Legality.Representation_Legality_Operational_Order_Value_Required;
   end Is_Operational_Error;

   function Layout_Error
     (Status : Editor.Ada_Record_Layout_Validation.Record_Layout_Status) return Boolean is
      use type Editor.Ada_Record_Layout_Validation.Record_Layout_Status;
   begin
      return Status /= Editor.Ada_Record_Layout_Validation.Record_Layout_Ok;
   end Layout_Error;

   procedure Clear (Model : in out Storage_Order_Rule_Model) is
   begin
      Model.Rules.Clear;
      Model.Explicit_Order_Component_Total := 0;
      Model.Bit_Order_Component_Total := 0;
      Model.Scalar_Order_Component_Total := 0;
      Model.Order_Conflict_Total := 0;
      Model.Operational_Error_Total := 0;
      Model.Layout_Error_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Apply_Order_Clause
     (Info  : Editor.Ada_Representation_Legality.Representation_Legality_Info;
      Rule  : in out Storage_Order_Rule_Info;
      Error : in out Boolean) is
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Order : constant Storage_Order_Value := Order_For (Info.Operational_Status);
   begin
      if Normalize (Info.Target_Name) /= Normalize (Rule.Target_Name) then
         return;
      end if;

      if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Bit_Order_Clause then
         Rule.Bit_Order_Clause := Info.Clause_Node;
         Rule.Bit_Order := Order;
      elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause then
         Rule.Scalar_Order_Clause := Info.Clause_Node;
         Rule.Scalar_Order := Order;
      end if;

      if Is_Operational_Error (Info) then
         Error := True;
      end if;
   end Apply_Order_Clause;

   procedure Count_Result
     (Model : in out Storage_Order_Rule_Model;
      Info  : Storage_Order_Rule_Info) is
   begin
      if Info.Bit_Order /= Storage_Order_None
        or else Info.Scalar_Order /= Storage_Order_None
      then
         Model.Explicit_Order_Component_Total :=
           Model.Explicit_Order_Component_Total + 1;
      end if;

      if Info.Bit_Order /= Storage_Order_None then
         Model.Bit_Order_Component_Total := Model.Bit_Order_Component_Total + 1;
      end if;

      if Info.Scalar_Order /= Storage_Order_None then
         Model.Scalar_Order_Component_Total := Model.Scalar_Order_Component_Total + 1;
      end if;

      case Info.Status is
         when Storage_Order_Rule_Order_Conflict =>
            Model.Order_Conflict_Total := Model.Order_Conflict_Total + 1;
         when Storage_Order_Rule_Operational_Error =>
            Model.Operational_Error_Total := Model.Operational_Error_Total + 1;
         when Storage_Order_Rule_Layout_Error =>
            Model.Layout_Error_Total := Model.Layout_Error_Total + 1;
         when Storage_Order_Rule_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when others =>
            null;
      end case;
   end Count_Result;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout   : Editor.Ada_Record_Layout_Validation.Record_Layout_Model)
      return Storage_Order_Rule_Model is
      Result : Storage_Order_Rule_Model;
   begin
      for Index in 1 .. Editor.Ada_Record_Layout_Validation.Check_Count (Layout) loop
         declare
            Layout_Info : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Info :=
              Editor.Ada_Record_Layout_Validation.Check_At (Layout, Index);
            Rule : Storage_Order_Rule_Info;
            Operational_Error : Boolean := False;
         begin
            Rule.Component_Node := Layout_Info.Component_Node;
            Rule.Parent_Clause := Layout_Info.Parent_Clause;
            Rule.Target_Name := Layout_Info.Target_Name;
            Rule.Component_Name := Layout_Info.Component_Name;
            Rule.Layout_Status := Layout_Info.Status;
            Rule.Source_Line := Layout_Info.Source_Line;

            for Check_Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
               declare
                  Check : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
                    Editor.Ada_Representation_Legality.Check_At (Legality, Check_Index);
               begin
                  Apply_Order_Clause (Check, Rule, Operational_Error);
               end;
            end loop;

            if Layout_Error (Rule.Layout_Status) then
               Rule.Status := Storage_Order_Rule_Layout_Error;
            elsif Operational_Error
              or else Rule.Bit_Order = Storage_Order_Unknown
              or else Rule.Scalar_Order = Storage_Order_Unknown
            then
               Rule.Status := Storage_Order_Rule_Operational_Error;
            elsif Rule.Bit_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First
              and then Rule.Scalar_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First
              and then Rule.Bit_Order /= Rule.Scalar_Order
            then
               Rule.Status := Storage_Order_Rule_Order_Conflict;
            elsif Rule.Bit_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First
              and then Rule.Scalar_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First
            then
               Rule.Status := Storage_Order_Rule_Bit_And_Scalar_Order_Applied;
            elsif Rule.Bit_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First then
               Rule.Status := Storage_Order_Rule_Bit_Order_Applied;
            elsif Rule.Scalar_Order in Storage_Order_High_Order_First | Storage_Order_Low_Order_First then
               Rule.Status := Storage_Order_Rule_Scalar_Storage_Order_Applied;
            elsif Rule.Bit_Order = Storage_Order_None
              and then Rule.Scalar_Order = Storage_Order_None
            then
               Rule.Status := Storage_Order_Rule_No_Explicit_Order;
            else
               Rule.Status := Storage_Order_Rule_Unknown;
            end if;

            Rule.Fingerprint :=
              Mix (Natural (Rule.Component_Node),
                   Mix (Natural (Rule.Parent_Clause),
                        Mix (Rule.Source_Line,
                             Mix (Storage_Order_Rule_Status'Pos (Rule.Status),
                                  Mix (Storage_Order_Value'Pos (Rule.Bit_Order),
                                       Storage_Order_Value'Pos (Rule.Scalar_Order))))));

            Result.Rules.Append (Rule);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Rule.Fingerprint);
            Count_Result (Result, Rule);
         end;
      end loop;

      return Result;
   end Build;

   function Rule_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Natural (Model.Rules.Length);
   end Rule_Count;

   function Rule_At
     (Model : Storage_Order_Rule_Model;
      Index : Positive) return Storage_Order_Rule_Info is
   begin
      return Model.Rules (Index);
   end Rule_At;

   function Explicit_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Explicit_Order_Component_Total;
   end Explicit_Order_Component_Count;

   function Bit_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Bit_Order_Component_Total;
   end Bit_Order_Component_Count;

   function Scalar_Storage_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Scalar_Order_Component_Total;
   end Scalar_Storage_Order_Component_Count;

   function Order_Conflict_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Order_Conflict_Total;
   end Order_Conflict_Count;

   function Operational_Error_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Operational_Error_Total;
   end Operational_Error_Count;

   function Layout_Error_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Layout_Error_Total;
   end Layout_Error_Count;

   function Unknown_Count (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Storage_Order_Rule_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Record_Storage_Order_Rules;
