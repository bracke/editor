with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;

package body Editor.Ada_Generic_Formal_Type_Conformance is

   use type Editor.Ada_Type_Graph.Type_Id;

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

   function Shape_For_Label (Label : String) return Formal_Type_Shape is
      L : constant String := Normalize (Label);
   begin
      if Ada.Strings.Fixed.Index (L, " access ") /= 0
        or else Ada.Strings.Fixed.Index (L, " access") /= 0
      then
         return Formal_Type_Shape_Access;
      elsif Ada.Strings.Fixed.Index (L, "interface") /= 0 then
         return Formal_Type_Shape_Interface;
      elsif Ada.Strings.Fixed.Index (L, " is new ") /= 0 then
         return Formal_Type_Shape_Derived;
      elsif Ada.Strings.Fixed.Index (L, "private") /= 0 then
         return Formal_Type_Shape_Private;
      elsif Ada.Strings.Fixed.Index (L, "range <>") /= 0
        or else Ada.Strings.Fixed.Index (L, "mod <>") /= 0
      then
         return Formal_Type_Shape_Discrete;
      elsif Ada.Strings.Fixed.Index (L, "digits <>") /= 0
        or else Ada.Strings.Fixed.Index (L, "delta <>") /= 0
      then
         return Formal_Type_Shape_Scalar;
      elsif Ada.Strings.Fixed.Index (L, "array") /= 0 then
         return Formal_Type_Shape_Array;
      elsif Ada.Strings.Fixed.Index (L, "record") /= 0 then
         return Formal_Type_Shape_Record;
      else
         return Formal_Type_Shape_Unknown;
      end if;
   end Shape_For_Label;

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

   function Categories_Compatible
     (Shape  : Formal_Type_Shape;
      Actual : Editor.Ada_Type_Graph.Type_Info) return Boolean
   is
      use type Editor.Ada_Type_Graph.Type_Category;
   begin
      case Shape is
         when Formal_Type_Shape_Private =>
            return Actual.Category /= Editor.Ada_Type_Graph.Type_Category_Unknown;
         when Formal_Type_Shape_Interface =>
            return Actual.Category = Editor.Ada_Type_Graph.Type_Category_Interface
              or else Actual.Category = Editor.Ada_Type_Graph.Type_Category_Derived;
         when Formal_Type_Shape_Access =>
            return Actual.Category = Editor.Ada_Type_Graph.Type_Category_Access;
         when Formal_Type_Shape_Derived =>
            return Actual.Id /= Editor.Ada_Type_Graph.No_Type;
         when Formal_Type_Shape_Discrete =>
            return Actual.Category in
              Editor.Ada_Type_Graph.Type_Category_Integer |
              Editor.Ada_Type_Graph.Type_Category_Modular |
              Editor.Ada_Type_Graph.Type_Category_Subtype |
              Editor.Ada_Type_Graph.Type_Category_Derived;
         when Formal_Type_Shape_Scalar =>
            return Actual.Category in
              Editor.Ada_Type_Graph.Type_Category_Integer |
              Editor.Ada_Type_Graph.Type_Category_Modular |
              Editor.Ada_Type_Graph.Type_Category_Floating |
              Editor.Ada_Type_Graph.Type_Category_Fixed |
              Editor.Ada_Type_Graph.Type_Category_Subtype |
              Editor.Ada_Type_Graph.Type_Category_Derived;
         when Formal_Type_Shape_Array =>
            return Actual.Category = Editor.Ada_Type_Graph.Type_Category_Array;
         when Formal_Type_Shape_Record =>
            return Actual.Category = Editor.Ada_Type_Graph.Type_Category_Record
              or else Actual.Category = Editor.Ada_Type_Graph.Type_Category_Private;
         when Formal_Type_Shape_Unknown =>
            return Actual.Id /= Editor.Ada_Type_Graph.No_Type;
      end case;
   end Categories_Compatible;

   function Status_For
     (Types       : Editor.Ada_Type_Graph.Type_Model;
      Shape       : Formal_Type_Shape;
      Formal_Type : Editor.Ada_Type_Graph.Type_Info;
      Actual      : Editor.Ada_Type_Graph.Type_Info;
      Actual_Text : String) return Formal_Type_Conformance_Status
   is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_View_Status;
   begin
      if Trim (Actual_Text) = "" then
         return Formal_Type_Conformance_Actual_Missing;
      elsif Actual.Id = Editor.Ada_Type_Graph.No_Type then
         return Formal_Type_Conformance_Actual_Unresolved;
      elsif not Categories_Compatible (Shape, Actual) then
         return Formal_Type_Conformance_Category_Mismatch;
      end if;

      case Shape is
         when Formal_Type_Shape_Derived =>
            if Formal_Type.Base_Type = Editor.Ada_Type_Graph.No_Type
              and then Length (Formal_Type.Normalized_Base) = 0
            then
               return Formal_Type_Conformance_Base_Mismatch;
            elsif Formal_Type.Base_Type /= Editor.Ada_Type_Graph.No_Type
              and then (Actual.Id = Formal_Type.Base_Type
                        or else Editor.Ada_Type_Graph.Is_Derived_From
                          (Types, Actual.Id, Formal_Type.Base_Type))
            then
               return Formal_Type_Conformance_Derived_Compatible;
            elsif Length (Formal_Type.Normalized_Base) > 0
              and then To_String (Actual.Normalized_Name) = To_String (Formal_Type.Normalized_Base)
            then
               return Formal_Type_Conformance_Derived_Compatible;
            else
               return Formal_Type_Conformance_Base_Mismatch;
            end if;

         when Formal_Type_Shape_Private =>
            if Actual.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Completion_Unresolved then
               return Formal_Type_Conformance_Private_View_Unknown;
            else
               return Formal_Type_Conformance_Private_Compatible;
            end if;

         when Formal_Type_Shape_Interface =>
            return Formal_Type_Conformance_Interface_Compatible;

         when Formal_Type_Shape_Access =>
            if Length (Actual.Normalized_Base) = 0
              and then Actual.Base_Type = Editor.Ada_Type_Graph.No_Type
            then
               return Formal_Type_Conformance_Access_Designated_Unknown;
            else
               return Formal_Type_Conformance_Access_Compatible;
            end if;

         when Formal_Type_Shape_Discrete |
              Formal_Type_Shape_Scalar |
              Formal_Type_Shape_Array |
              Formal_Type_Shape_Record |
              Formal_Type_Shape_Unknown =>
            return Formal_Type_Conformance_Compatible;
      end case;
   end Status_For;

   procedure Add_Check
     (Model : in out Formal_Type_Conformance_Model;
      Info  : in out Formal_Type_Conformance_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Instance),
             Mix (Natural (Info.Formal),
                  Mix (Natural (Info.Instance_Node),
                       Mix (Natural (Info.Formal_Node),
                            Mix (Natural (Info.Formal_Type),
                                 Mix (Natural (Info.Actual_Type),
                                      Mix (Formal_Type_Shape'Pos (Info.Formal_Shape),
                                           Formal_Type_Conformance_Status'Pos (Info.Status))))))));

      case Info.Status is
         when Formal_Type_Conformance_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when Formal_Type_Conformance_Derived_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
            Model.Derived_Compatible_Total := Model.Derived_Compatible_Total + 1;
         when Formal_Type_Conformance_Private_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
            Model.Private_Compatible_Total := Model.Private_Compatible_Total + 1;
         when Formal_Type_Conformance_Interface_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
            Model.Interface_Compatible_Total := Model.Interface_Compatible_Total + 1;
         when Formal_Type_Conformance_Access_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
            Model.Access_Compatible_Total := Model.Access_Compatible_Total + 1;
         when Formal_Type_Conformance_Actual_Missing |
              Formal_Type_Conformance_Actual_Unresolved |
              Formal_Type_Conformance_Private_View_Unknown |
              Formal_Type_Conformance_Access_Designated_Unknown |
              Formal_Type_Conformance_Unsupported =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when Formal_Type_Conformance_Category_Mismatch |
              Formal_Type_Conformance_Base_Mismatch =>
            Model.Mismatch_Total := Model.Mismatch_Total + 1;
      end case;

      Model.Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Check;

   procedure Clear (Model : in out Formal_Type_Conformance_Model) is
   begin
      Model.Checks.Clear;
      Model.Compatible_Total := 0;
      Model.Mismatch_Total := 0;
      Model.Unresolved_Total := 0;
      Model.Private_Compatible_Total := 0;
      Model.Interface_Compatible_Total := 0;
      Model.Access_Compatible_Total := 0;
      Model.Derived_Compatible_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Types     : Editor.Ada_Type_Graph.Type_Model)
      return Formal_Type_Conformance_Model
   is
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Type_Graph.Type_Id;
      Result : Formal_Type_Conformance_Model;
   begin
      for Match_Index in 1 .. Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) loop
         declare
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_At (Contracts, Match_Index);
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance (Contracts, Match.Instance);
         begin
            if Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
              or else Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Kind_Mismatch
            then
               for Formal_Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
                  declare
                     Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                       Editor.Ada_Generic_Contracts.Formal_At (Contracts, Formal_Index);
                  begin
                     if Formal.Region = Match.Generic_Formal_Region
                       and then Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Type
                     then
                        declare
                           Actual_Text : constant String :=
                             Actual_Text_For_Formal (Contracts, Instance, Formal);
                           Formal_Type_Id : constant Editor.Ada_Type_Graph.Type_Id :=
                             Editor.Ada_Type_Graph.Type_For_Declaration
                               (Types, Formal.Declaration);
                           Formal_Type : constant Editor.Ada_Type_Graph.Type_Info :=
                             (if Formal_Type_Id /= Editor.Ada_Type_Graph.No_Type
                              then Editor.Ada_Type_Graph.Type_Node (Types, Formal_Type_Id)
                              else Type_By_Normalized_Name
                                (Types, To_String (Formal.Normalized_Name)));
                           Actual_Type : constant Editor.Ada_Type_Graph.Type_Info :=
                             Type_By_Normalized_Name (Types, Actual_Text);
                           Info : Formal_Type_Conformance_Info;
                        begin
                           Info.Instance := Instance.Id;
                           Info.Formal := Formal.Id;
                           Info.Instance_Node := Instance.Node;
                           Info.Formal_Node := Formal.Node;
                           Info.Formal_Type := Formal_Type.Id;
                           Info.Actual_Type := Actual_Type.Id;
                           Info.Formal_Name := Formal.Name;
                           Info.Actual_Text := To_Unbounded_String (Actual_Text);
                           Info.Formal_Shape := Shape_For_Label (Formal_Label (Tree, Formal));
                           Info.Status := Status_For
                             (Types, Info.Formal_Shape, Formal_Type, Actual_Type, Actual_Text);
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

   function Check_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Formal_Type_Conformance_Model;
      Index : Positive) return Formal_Type_Conformance_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Mismatch_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Mismatch_Total;
   end Mismatch_Count;

   function Unresolved_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Private_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Private_Compatible_Total;
   end Private_Compatible_Count;

   function Interface_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Interface_Compatible_Total;
   end Interface_Compatible_Count;

   function Access_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Access_Compatible_Total;
   end Access_Compatible_Count;

   function Derived_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Derived_Compatible_Total;
   end Derived_Compatible_Count;

   function Fingerprint (Model : Formal_Type_Conformance_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Formal_Type_Conformance;
