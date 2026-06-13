with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;

package body Editor.Ada_Generic_Object_Default_Type_Conformance is

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Delimited_Text_At
     (List  : String;
      Index : Positive) return String
   is
      First : Natural := List'First;
      Pos   : Positive := 1;
   begin
      if List = "" then
         return "";
      end if;

      while First <= List'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (List (First .. List'Last), "|");
            Last : Natural := List'Last;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;

            if Pos = Index then
               return Trim (List (First .. Last));
            end if;

            exit when Sep = 0;
            First := Sep + 1;
            Pos := Pos + 1;
         end;
      end loop;

      return "";
   end Delimited_Text_At;

   function Named_Text_For
     (List : String;
      Name : String) return String
   is
      N     : constant String := Normalize (Name);
      First : Natural := List'First;
   begin
      if List = "" or else N = "" then
         return "";
      end if;

      while First <= List'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (List (First .. List'Last), "|");
            Last : Natural := List'Last;
            Eq   : Natural;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;

            Eq := Ada.Strings.Fixed.Index (List (First .. Last), "=");
            if Eq /= 0 and then Normalize (List (First .. Eq - 1)) = N then
               return Trim (List (Eq + 1 .. Last));
            end if;

            exit when Sep = 0;
            First := Sep + 1;
         end;
      end loop;

      return "";
   end Named_Text_For;

   function Formal_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal : Editor.Ada_Generic_Contracts.Generic_Formal_Info) return String is
      use type Editor.Ada_Syntax_Tree.Node_Id;
   begin
      if Formal.Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      else
         return To_String (Editor.Ada_Syntax_Tree.Node (Tree, Formal.Node).Label);
      end if;
   end Formal_Label;

   function Formal_Subtype_From_Label
     (Label       : String;
      Formal_Name : String) return String
   is
      L     : constant String := Trim (Label);
      Colon : Natural := Ada.Strings.Fixed.Index (L, ":");
      Assign : Natural;
      Semi   : Natural;
      First  : Natural;
      Last   : Natural;
      pragma Unreferenced (Formal_Name);
   begin
      if Colon = 0 then
         return "";
      end if;

      First := Colon + 1;
      while First <= L'Last and then L (First) = ' ' loop
         First := First + 1;
      end loop;

      if First + 7 <= L'Last and then Normalize (L (First .. First + 7)) = "constant" then
         First := First + 8;
         while First <= L'Last and then L (First) = ' ' loop
            First := First + 1;
         end loop;
      end if;

      Assign := Ada.Strings.Fixed.Index (L (First .. L'Last), ":=");
      Semi := Ada.Strings.Fixed.Index (L (First .. L'Last), ";");
      Last := L'Last;
      if Assign /= 0 then
         Last := Assign - 1;
      elsif Semi /= 0 then
         Last := Semi - 1;
      end if;

      if First > Last then
         return "";
      else
         return Trim (L (First .. Last));
      end if;
   end Formal_Subtype_From_Label;

   function Type_By_Normalized_Name
     (Types : Editor.Ada_Type_Graph.Type_Model;
      Name  : String) return Editor.Ada_Type_Graph.Type_Info
   is
      N : constant String := Normalize (Name);
   begin
      if N = "" then
         return (others => <>);
      end if;

      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = N then
               return Info;
            end if;
         end;
      end loop;

      return (others => <>);
   end Type_By_Normalized_Name;

   function Actual_Text_For_Formal
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Instance  : Editor.Ada_Generic_Contracts.Generic_Instance_Info;
      Formal    : Editor.Ada_Generic_Contracts.Generic_Formal_Info) return String
   is
      Position : Natural := 0;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Candidate : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Index);
         begin
            if Candidate.Region = Formal.Region then
               Position := Position + 1;
               if Candidate.Id = Formal.Id then
                  if Position <= Instance.Positional_Actuals then
                     return Delimited_Text_At
                       (To_String (Instance.Positional_Actual_Texts),
                        Positive (Position));
                  else
                     return Named_Text_For
                       (To_String (Instance.Named_Actual_Texts),
                        To_String (Formal.Normalized_Name));
                  end if;
               end if;
            end if;
         end;
      end loop;

      return "";
   end Actual_Text_For_Formal;

   function Compatible_Static_With_Type
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info;
      Typ   : Editor.Ada_Type_Graph.Type_Info) return Boolean
   is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      use type Editor.Ada_Type_Graph.Type_Category;
   begin
      if Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
         return Typ.Category in
           Editor.Ada_Type_Graph.Type_Category_Integer |
           Editor.Ada_Type_Graph.Type_Category_Modular |
           Editor.Ada_Type_Graph.Type_Category_Fixed |
           Editor.Ada_Type_Graph.Type_Category_Floating |
           Editor.Ada_Type_Graph.Type_Category_Subtype |
           Editor.Ada_Type_Graph.Type_Category_Derived |
           Editor.Ada_Type_Graph.Type_Category_Formal;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
         if Typ.Category = Editor.Ada_Type_Graph.Type_Category_Subtype
           and then (Ada.Strings.Fixed.Index (To_String (Typ.Normalized_Base), "integer") /= 0
                     or else Ada.Strings.Fixed.Index (To_String (Typ.Normalized_Base), "natural") /= 0
                     or else Ada.Strings.Fixed.Index (To_String (Typ.Normalized_Base), "positive") /= 0)
         then
            return False;
         end if;

         return Typ.Category in
           Editor.Ada_Type_Graph.Type_Category_Floating |
           Editor.Ada_Type_Graph.Type_Category_Fixed |
           Editor.Ada_Type_Graph.Type_Category_Subtype |
           Editor.Ada_Type_Graph.Type_Category_Derived |
           Editor.Ada_Type_Graph.Type_Category_Formal;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal then
         return Typ.Category in
           Editor.Ada_Type_Graph.Type_Category_Subtype |
           Editor.Ada_Type_Graph.Type_Category_Derived |
           Editor.Ada_Type_Graph.Type_Category_Formal |
           Editor.Ada_Type_Graph.Type_Category_Unknown;
      else
         return False;
      end if;
   end Compatible_Static_With_Type;

   function Has_Integer_Range_Error
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Typ    : Editor.Ada_Type_Graph.Type_Info;
      Value  : Editor.Ada_Static_Expressions.Static_Value_Info) return Boolean
   is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
   begin
      if Value.Status /= Editor.Ada_Static_Expressions.Static_Value_Integer then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Static) loop
         declare
            Bounds : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Static, Index);
         begin
            if To_String (Bounds.Normalized_Name) = To_String (Typ.Normalized_Name)
              and then Editor.Ada_Static_Expressions.Is_Static_Integer (Bounds.First_Value)
              and then Editor.Ada_Static_Expressions.Is_Static_Integer (Bounds.Last_Value)
            then
               return Value.Integer_Value < Bounds.First_Value.Integer_Value
                 or else Value.Integer_Value > Bounds.Last_Value.Integer_Value;
            end if;
         end;
      end loop;

      return False;
   end Has_Integer_Range_Error;

   function Status_For
     (Static      : Editor.Ada_Static_Expressions.Static_Model;
      Formal_Type : Editor.Ada_Type_Graph.Type_Info;
      Expr_Value  : Editor.Ada_Static_Expressions.Static_Value_Info;
      Expression  : String;
      Is_Default  : Boolean) return Object_Default_Type_Status
   is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
   begin
      if Trim (Expression) = "" then
         if Is_Default then
            return Object_Default_Type_Default_Missing;
         else
            return Object_Default_Type_Actual_Missing;
         end if;
      elsif Formal_Type.Id = Editor.Ada_Type_Graph.No_Type then
         return Object_Default_Type_Formal_Subtype_Unknown;
      elsif Expr_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero
        or else Expr_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Malformed
        or else Expr_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Non_Static
        or else Expr_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name
      then
         return Object_Default_Type_Static_Value_Unknown;
      elsif Has_Integer_Range_Error (Static, Formal_Type, Expr_Value) then
         return Object_Default_Type_Static_Range_Error;
      elsif not Compatible_Static_With_Type (Expr_Value, Formal_Type) then
         if Is_Default then
            return Object_Default_Type_Default_Type_Mismatch;
         else
            return Object_Default_Type_Actual_Type_Mismatch;
         end if;
      elsif Is_Default then
         return Object_Default_Type_Default_Compatible;
      else
         return Object_Default_Type_Actual_Compatible;
      end if;
   end Status_For;

   procedure Add_Check
     (Model : in out Object_Default_Type_Model;
      Info  : in out Object_Default_Type_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Instance),
             Mix (Natural (Info.Formal),
                  Mix (Natural (Info.Instance_Node),
                       Mix (Natural (Info.Formal_Node),
                            Mix (Natural (Info.Formal_Type),
                                 Mix (Editor.Ada_Static_Expressions.Static_Value_Status'Pos (Info.Static_Status),
                                      Object_Default_Type_Status'Pos (Info.Status)))))));

      if Info.Is_Default then
         Model.Default_Checked_Total := Model.Default_Checked_Total + 1;
      else
         Model.Actual_Checked_Total := Model.Actual_Checked_Total + 1;
      end if;

      case Info.Status is
         when Object_Default_Type_Default_Compatible |
              Object_Default_Type_Actual_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when Object_Default_Type_Default_Type_Mismatch |
              Object_Default_Type_Actual_Type_Mismatch =>
            Model.Mismatch_Total := Model.Mismatch_Total + 1;
         when Object_Default_Type_Static_Range_Error =>
            Model.Range_Error_Total := Model.Range_Error_Total + 1;
         when Object_Default_Type_Static_Value_Unknown |
              Object_Default_Type_Formal_Subtype_Unknown |
              Object_Default_Type_Actual_Missing |
              Object_Default_Type_Default_Missing |
              Object_Default_Type_Unsupported =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
      end case;

      Model.Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Check;

   procedure Clear (Model : in out Object_Default_Type_Model) is
   begin
      Model.Checks.Clear;
      Model.Compatible_Total := 0;
      Model.Mismatch_Total := 0;
      Model.Range_Error_Total := 0;
      Model.Unknown_Total := 0;
      Model.Default_Checked_Total := 0;
      Model.Actual_Checked_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Static    : Editor.Ada_Static_Expressions.Static_Model;
      Types     : Editor.Ada_Type_Graph.Type_Model)
      return Object_Default_Type_Model
   is
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Result : Object_Default_Type_Model;
   begin
      for Match_Index in 1 .. Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) loop
         declare
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_At (Contracts, Match_Index);
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance (Contracts, Match.Instance);
         begin
            if Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
              or else Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Object_Default_Illegal
              or else Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Object_Default_Unknown
            then
               for Formal_Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
                  declare
                     Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                       Editor.Ada_Generic_Contracts.Formal_At (Contracts, Formal_Index);
                  begin
                     if Formal.Region = Match.Generic_Formal_Region
                       and then Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Object
                     then
                        declare
                           Label : constant String := Formal_Label (Tree, Formal);
                           Subtype_Text : constant String :=
                             Formal_Subtype_From_Label (Label, To_String (Formal.Name));
                           Formal_Type : constant Editor.Ada_Type_Graph.Type_Info :=
                             Type_By_Normalized_Name (Types, Subtype_Text);
                           Actual_Text : constant String :=
                             Actual_Text_For_Formal (Contracts, Instance, Formal);
                           Use_Default : constant Boolean := Trim (Actual_Text) = "";
                           Expr_Text : constant String :=
                             (if Use_Default then To_String (Formal.Default_Text) else Actual_Text);
                           Expr_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                             Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
                               (Static, Formal.Region, Expr_Text);
                           Info : Object_Default_Type_Info;
                        begin
                           Info.Instance := Instance.Id;
                           Info.Formal := Formal.Id;
                           Info.Instance_Node := Instance.Node;
                           Info.Formal_Node := Formal.Node;
                           Info.Formal_Type := Formal_Type.Id;
                           Info.Formal_Name := Formal.Name;
                           Info.Formal_Subtype := To_Unbounded_String (Subtype_Text);
                           Info.Expression_Text := To_Unbounded_String (Expr_Text);
                           Info.Is_Default := Use_Default;
                           Info.Static_Status := Expr_Value.Status;
                           Info.Status := Status_For
                             (Static, Formal_Type, Expr_Value, Expr_Text, Use_Default);
                           Info.Start_Line := Instance.Start_Line;
                           Info.End_Line := Instance.End_Line;
                           Add_Check (Result, Info);
                        end;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Build;

   function Check_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Object_Default_Type_Model;
      Index : Positive) return Object_Default_Type_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Compatible_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Mismatch_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Mismatch_Total;
   end Mismatch_Count;

   function Range_Error_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Range_Error_Total;
   end Range_Error_Count;

   function Unknown_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Default_Checked_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Default_Checked_Total;
   end Default_Checked_Count;

   function Actual_Checked_Count (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Actual_Checked_Total;
   end Actual_Checked_Count;

   function Fingerprint (Model : Object_Default_Type_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Object_Default_Type_Conformance;
