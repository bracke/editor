with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Selected_Name_Resolution is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Is_Name_Char (C : Character) return Boolean is
   begin
      return (C in 'A' .. 'Z') or else (C in 'a' .. 'z')
        or else (C in '0' .. '9') or else C = '_';
   end Is_Name_Char;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (C) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Selected_Name_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 71) mod Natural'Last;
   end Mix;

   function Empty_Selected_Name return Selected_Name_Info is
   begin
      return (Id => No_Selected_Name,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Prefix => Null_Unbounded_String,
              Selector => Null_Unbounded_String,
              Normalized_Prefix => Null_Unbounded_String,
              Normalized_Selector => Null_Unbounded_String,
              Prefix_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Prefix_Region => Editor.Ada_Declarative_Regions.No_Region,
              Selector_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Cross_Unit_Lookup =>
                Editor.Ada_Cross_Unit_Lookup_Integration.No_Cross_Unit_Lookup,
              Cross_Unit_Status =>
                Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found,
              Cross_Unit_Target => Null_Unbounded_String,
              Cross_Unit_Path => Null_Unbounded_String,
              Status => Selected_Name_Not_Resolved,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Selected_Name;

   function Last_Dot (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for I in Text'Range loop
         if Text (I) = '.' then
            Result := I;
         end if;
      end loop;
      return Result;
   end Last_Dot;

   function Clean_Prefix (Text : String) return String is
      T     : constant String := Trim (Text);
      First : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;

      for I in reverse T'Range loop
         if not Is_Name_Char (T (I)) and then T (I) /= '.' then
            First := I + 1;
            exit;
         elsif I = T'First then
            First := T'First;
         end if;
      end loop;

      if First > T'Last then
         return "";
      end if;
      return Trim (T (First .. T'Last));
   end Clean_Prefix;

   function Clean_Selector (Text : String) return String is
      T    : constant String := Trim (Text);
      Last : Natural := 0;
   begin
      if T = "" then
         return "";
      end if;

      for I in T'Range loop
         if Is_Name_Char (T (I)) then
            Last := I;
         else
            exit;
         end if;
      end loop;

      if Last = 0 then
         return "";
      end if;
      return T (T'First .. Last);
   end Clean_Selector;

   procedure Split_Selected_Name
     (Text     : String;
      Prefix   : out Unbounded_String;
      Selector : out Unbounded_String)
   is
      Dot : constant Natural := Last_Dot (Text);
   begin
      Prefix := Null_Unbounded_String;
      Selector := Null_Unbounded_String;
      if Dot = 0 or else Dot = Text'First or else Dot = Text'Last then
         return;
      end if;

      Prefix := To_Unbounded_String (Clean_Prefix (Text (Text'First .. Dot - 1)));
      Selector := To_Unbounded_String (Clean_Selector (Text (Dot + 1 .. Text'Last)));
   end Split_Selected_Name;



   function Status_For_Cross_Unit
     (Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Entry)
      return Selected_Name_Status is
   begin
      case Lookup.Status is
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible =>
            return Selected_Name_Cross_Unit_Prefix_Found;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Use_Visible =>
            return Selected_Name_Cross_Unit_Use_Prefix_Found;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Limited_Incomplete_View =>
            return Selected_Name_Cross_Unit_Limited_Prefix;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Private_View =>
            return Selected_Name_Cross_Unit_Private_Prefix;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Missing =>
            return Selected_Name_Cross_Unit_Prefix_Missing;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Ambiguous =>
            return Selected_Name_Cross_Unit_Prefix_Ambiguous;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Overflow =>
            return Selected_Name_Cross_Unit_Prefix_Overflow;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Local_Found =>
            return Selected_Name_Found;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Local_Ambiguous =>
            return Selected_Name_Prefix_Ambiguous;
         when Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found =>
            return Selected_Name_Prefix_Not_Found;
      end case;
   end Status_For_Cross_Unit;

   function Target_Region_For_Declaration
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Decl    : Editor.Ada_Direct_Visibility.Declaration_Info)
      return Editor.Ada_Declarative_Regions.Region_Id
   is
      Candidate : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Decl.Node);
      Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
        Editor.Ada_Declarative_Regions.Region (Regions, Candidate);
   begin
      if Candidate = Editor.Ada_Declarative_Regions.No_Region then
         return Editor.Ada_Declarative_Regions.No_Region;
      elsif Info.Owner_Node = Decl.Node then
         return Candidate;
      else
         return Editor.Ada_Declarative_Regions.No_Region;
      end if;
   end Target_Region_For_Declaration;

   function Resolve_Selected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Selected_Name_Info
   is
      pragma Unreferenced (Tree);
      Prefix_Text   : Unbounded_String;
      Selector_Text : Unbounded_String;
      Info          : Selected_Name_Info := Empty_Selected_Name;
      Prefix_Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Selector_Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Prefix_Decl   : Editor.Ada_Direct_Visibility.Declaration_Info;
   begin
      Split_Selected_Name (Name, Prefix_Text, Selector_Text);
      Info.Region := Region;
      Info.Prefix := Prefix_Text;
      Info.Selector := Selector_Text;
      Info.Normalized_Prefix := To_Unbounded_String (Normalize (To_String (Prefix_Text)));
      Info.Normalized_Selector := To_Unbounded_String (Normalize (To_String (Selector_Text)));

      if Region = Editor.Ada_Declarative_Regions.No_Region
        or else To_String (Prefix_Text) = ""
        or else To_String (Selector_Text) = ""
      then
         Info.Status := Selected_Name_Not_Resolved;
      else
         Prefix_Lookup :=
           Editor.Ada_Use_Visibility.Lookup_Visible
             (Visibility, Uses, Regions, Region, To_String (Prefix_Text));

         if Prefix_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
            Info.Status := Selected_Name_Prefix_Not_Found;
         elsif Prefix_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Status := Selected_Name_Prefix_Ambiguous;
            Info.Prefix_Declaration := Prefix_Lookup.Declaration;
         else
            Info.Prefix_Declaration := Prefix_Lookup.Declaration;
            Prefix_Decl := Editor.Ada_Direct_Visibility.Declaration
              (Visibility, Prefix_Lookup.Declaration);
            Info.Prefix_Region := Target_Region_For_Declaration (Regions, Prefix_Decl);

            if Info.Prefix_Region = Editor.Ada_Declarative_Regions.No_Region then
               Info.Status := Selected_Name_Prefix_Has_No_Region;
            else
               Selector_Lookup :=
                 Editor.Ada_Direct_Visibility.Lookup_Direct
                   (Visibility, Info.Prefix_Region, To_String (Selector_Text));
               if Selector_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
                  Info.Status := Selected_Name_Selector_Not_Found;
               elsif Selector_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                  Info.Status := Selected_Name_Selector_Ambiguous;
                  Info.Selector_Declaration := Selector_Lookup.Declaration;
               else
                  Info.Status := Selected_Name_Found;
                  Info.Selector_Declaration := Selector_Lookup.Declaration;
               end if;
            end if;
         end if;
      end if;

      Info.Fingerprint :=
        (Selected_Name_Status'Pos (Info.Status) * 1000003
         + Natural (Region) * 1009
         + Natural (Info.Prefix_Declaration) * 97
         + Natural (Info.Prefix_Region) * 53
         + Natural (Info.Selector_Declaration) * 17
         + Hash_Text (To_String (Info.Normalized_Prefix)) * 11
         + Hash_Text (To_String (Info.Normalized_Selector))) mod Natural'Last;
      return Info;
   end Resolve_Selected;



   function Resolve_Selected_With_Cross_Unit
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Cross_Unit : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Selected_Name_Info
   is
      Info          : Selected_Name_Info :=
        Resolve_Selected (Tree, Regions, Visibility, Uses, Region, Name);
      Prefix_Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Cross_Lookup  : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Entry;
   begin
      if Info.Status /= Selected_Name_Prefix_Not_Found then
         return Info;
      end if;

      Prefix_Lookup :=
        Editor.Ada_Use_Visibility.Lookup_Visible
          (Visibility, Uses, Regions, Region, To_String (Info.Prefix));
      Cross_Lookup :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Resolve_With_Local
          (Cross_Unit, Prefix_Lookup, To_String (Info.Prefix));

      if Cross_Lookup.Status =
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found
      then
         return Info;
      end if;

      Info.Cross_Unit_Lookup := Cross_Lookup.Id;
      Info.Cross_Unit_Status := Cross_Lookup.Status;
      Info.Cross_Unit_Target := Cross_Lookup.Target_Unit_Name;
      Info.Cross_Unit_Path := Cross_Lookup.Target_Path;
      Info.Status := Status_For_Cross_Unit (Cross_Lookup);
      Info.Fingerprint :=
        (Info.Fingerprint
         + Cross_Lookup.Fingerprint * 89
         + Natural (Cross_Lookup.Id) * 41
         + Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status'Pos
             (Cross_Lookup.Status) * 23) mod Natural'Last;
      return Info;
   end Resolve_Selected_With_Cross_Unit;

   procedure Clear (Model : in out Selected_Name_Model) is
   begin
      Model.Names.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model)
      return Selected_Name_Model
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Model : Selected_Name_Model;
   begin
      Clear (Model);

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Selected_Name then
               declare
                  Info : Selected_Name_Info :=
                    Resolve_Selected
                      (Tree,
                       Regions,
                       Visibility,
                       Uses,
                       Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id),
                       To_String (Node.Label));
               begin
                  Info.Id := Selected_Name_Id (Natural (Model.Names.Length) + 1);
                  Info.Node := Node.Id;
                  Info.Start_Line := Node.Source_Span.Start_Line;
                  Info.End_Line := Node.Source_Span.End_Line;
                  Info.Fingerprint :=
                    (Info.Fingerprint
                     + Natural (Info.Id) * 131
                     + Natural (Info.Node) * 37
                     + Node.Source_Span.Start_Line * 19
                     + Node.Source_Span.End_Line * 7) mod Natural'Last;
                  Model.Names.Append (Info);
                  Mix (Model, Info.Fingerprint);
               end;
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      Mix (Model, Editor.Ada_Use_Visibility.Fingerprint (Uses));
      return Model;
   end Build;



   function Build_With_Cross_Unit
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Cross_Unit : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model)
      return Selected_Name_Model
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Model : Selected_Name_Model;
   begin
      Clear (Model);

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Selected_Name then
               declare
                  Info : Selected_Name_Info :=
                    Resolve_Selected_With_Cross_Unit
                      (Tree,
                       Regions,
                       Visibility,
                       Uses,
                       Cross_Unit,
                       Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id),
                       To_String (Node.Label));
               begin
                  Info.Id := Selected_Name_Id (Natural (Model.Names.Length) + 1);
                  Info.Node := Node.Id;
                  Info.Start_Line := Node.Source_Span.Start_Line;
                  Info.End_Line := Node.Source_Span.End_Line;
                  Info.Fingerprint :=
                    (Info.Fingerprint
                     + Natural (Info.Id) * 131
                     + Natural (Info.Node) * 37
                     + Node.Source_Span.Start_Line * 19
                     + Node.Source_Span.End_Line * 7) mod Natural'Last;
                  Model.Names.Append (Info);
                  Mix (Model, Info.Fingerprint);
               end;
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      Mix (Model, Editor.Ada_Direct_Visibility.Fingerprint (Visibility));
      Mix (Model, Editor.Ada_Use_Visibility.Fingerprint (Uses));
      Mix (Model, Editor.Ada_Cross_Unit_Lookup_Integration.Fingerprint (Cross_Unit));
      return Model;
   end Build_With_Cross_Unit;

   function Has_Selected_Names (Model : Selected_Name_Model) return Boolean is
   begin
      return not Model.Names.Is_Empty;
   end Has_Selected_Names;

   function Selected_Name_Count (Model : Selected_Name_Model) return Natural is
   begin
      return Natural (Model.Names.Length);
   end Selected_Name_Count;

   function Selected_Name_At
     (Model : Selected_Name_Model;
      Index : Positive) return Selected_Name_Info
   is
   begin
      if Index > Natural (Model.Names.Length) then
         return Empty_Selected_Name;
      end if;
      return Model.Names (Index);
   end Selected_Name_At;

   function Selected_Name
     (Model : Selected_Name_Model;
      Id    : Selected_Name_Id) return Selected_Name_Info
   is
   begin
      if Id = No_Selected_Name or else Natural (Id) > Natural (Model.Names.Length) then
         return Empty_Selected_Name;
      end if;
      return Model.Names (Positive (Id));
   end Selected_Name;

   function Selected_Name_For_Node
     (Model : Selected_Name_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Selected_Name_Info
   is
   begin
      for Info of Model.Names loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Selected_Name;
   end Selected_Name_For_Node;

   function Fingerprint (Model : Selected_Name_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Selected_Name_Resolution;
