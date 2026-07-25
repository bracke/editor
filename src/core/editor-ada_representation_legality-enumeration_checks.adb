with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Representation_Legality.Core_Utilities;
with Editor.Ada_Representation_Legality.Clause_Classification;
with Editor.Ada_Representation_Legality.Target_Compatibility;
with Editor.Ada_Representation_Legality.Static_Value_Checks;

package body Editor.Ada_Representation_Legality.Enumeration_Checks is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Language_Model.Representation_Source_Form;

   function Mix (A, B : Natural) return Natural
     renames Editor.Ada_Representation_Legality.Core_Utilities.Mix;

   function Trimmed (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Trimmed;

   function Lower (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Lower;

   function Normalized (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Child_Label;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Declaration_Name;

   function Name_List_Contains (List_Text, Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Name_List_Contains;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Has_Record_Component;

   function Strip_Leading_At (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Strip_Leading_At;

   function Range_First (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_First;

   function Range_Last (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_Last;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info
     renames Editor.Ada_Representation_Legality.Check_For_Clause;

   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Value_Status_For;



   function Is_Enumeration_Type_Node
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Boolean is
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               return True;
            end if;
         end;
      end loop;

      declare
         Def : constant String :=
           Trimmed (Child_Label (Tree, Type_Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
      begin
         return Def'Length >= 2
           and then Def (Def'First) = '('
           and then Def (Def'Last) = ')';
      end;
   end Is_Enumeration_Type_Node;

   function Enumeration_Definition_Text
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return String is
      Def : constant String :=
        Trimmed (Child_Label (Tree, Type_Node, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype));
   begin
      if Def'Length >= 2
        and then Def (Def'First) = '('
        and then Def (Def'Last) = ')'
      then
         return Def (Def'First + 1 .. Def'Last - 1);
      end if;
      return "";
   end Enumeration_Definition_Text;

   function Enumeration_Definition_Count (Definition : String) return Natural is
      Count : Natural := 0;
      First : Natural := Definition'First;
   begin
      if Trimmed (Definition) = "" then
         return 0;
      end if;

      for I in Definition'Range loop
         if Definition (I) = ',' then
            if Trimmed (Definition (First .. I - 1)) /= "" then
               Count := Count + 1;
            end if;
            First := I + 1;
         end if;
      end loop;
      if First <= Definition'Last and then Trimmed (Definition (First .. Definition'Last)) /= "" then
         Count := Count + 1;
      end if;
      return Count;
   end Enumeration_Definition_Count;

   function Enumeration_Definition_Name_At
     (Definition : String;
      Position   : Positive) return String is
      Count : Natural := 0;
      First : Natural := Definition'First;
   begin
      for I in Definition'Range loop
         if Definition (I) = ',' then
            declare
               Name : constant String := Trimmed (Definition (First .. I - 1));
            begin
               if Name /= "" then
                  Count := Count + 1;
                  if Count = Position then
                     return Name;
                  end if;
               end if;
            end;
            First := I + 1;
         end if;
      end loop;

      if First <= Definition'Last then
         declare
            Name : constant String := Trimmed (Definition (First .. Definition'Last));
         begin
            if Name /= "" then
               Count := Count + 1;
               if Count = Position then
                  return Name;
               end if;
            end if;
         end;
      end if;
      return "";
   end Enumeration_Definition_Name_At;

   function Enumeration_Literal_Count
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return 0;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
            end if;
         end;
      end loop;
      if Count /= 0 then
         return Count;
      end if;
      return Enumeration_Definition_Count (Enumeration_Definition_Text (Tree, Type_Node));
   end Enumeration_Literal_Count;

   function Enumeration_Literal_Name_At
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Position  : Positive) return String is
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
               if Count = Position then
                  return Child_Label
                    (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
               end if;
            end if;
         end;
      end loop;
      return Enumeration_Definition_Name_At
        (Enumeration_Definition_Text (Tree, Type_Node), Position);
   end Enumeration_Literal_Name_At;

   function Enumeration_Literal_Exists
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node or else N = "" then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration
              and then Lower (Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name)) = N
            then
               return True;
            end if;
         end;
      end loop;
      for Pos in 1 .. Enumeration_Definition_Count (Enumeration_Definition_Text (Tree, Type_Node)) loop
         if Lower (Enumeration_Definition_Name_At
                     (Enumeration_Definition_Text (Tree, Type_Node), Pos)) = N
         then
            return True;
         end if;
      end loop;
      return False;
   end Enumeration_Literal_Exists;

   function Enumeration_Literal_Position
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Natural is
      N : constant String := Lower (Name);
      Count : Natural := 0;
   begin
      if Type_Node = Editor.Ada_Syntax_Tree.No_Node or else N = "" then
         return 0;
      end if;

      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Type_Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Type_Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
               Count := Count + 1;
               if Lower (Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name)) = N then
                  return Count;
               end if;
            end if;
         end;
      end loop;
      for Pos in 1 .. Enumeration_Definition_Count (Enumeration_Definition_Text (Tree, Type_Node)) loop
         if Lower (Enumeration_Definition_Name_At
                     (Enumeration_Definition_Text (Tree, Type_Node), Pos)) = N
         then
            return Pos;
         end if;
      end loop;
      return 0;
   end Enumeration_Literal_Position;

   function Enumeration_Literal_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         declare
            Prior : constant Enumeration_Representation_Legality_Info :=
              Model.Enumeration_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then To_String (Prior.Normalized_Literal) = Normalized_Name
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Enumeration_Literal_Duplicate;

   function Enumeration_Value_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Static_Value  : Long_Long_Integer) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         declare
            Prior : constant Enumeration_Representation_Legality_Info :=
              Model.Enumeration_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then Prior.Value_Status = Representation_Value_Static_Integer
              and then Prior.Static_Value = Static_Value
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Enumeration_Value_Duplicate;

   procedure Count_Enumeration_Result
     (Model : in out Representation_Legality_Model;
      Info  : Enumeration_Representation_Legality_Info) is
   begin
      if Info.Status /= Representation_Legality_Ok then
         Model.Enumeration_Error_Total := Model.Enumeration_Error_Total + 1;
         if Info.Status = Representation_Legality_Enumeration_Literal_Duplicate then
            Model.Enumeration_Duplicate_Literal_Total :=
              Model.Enumeration_Duplicate_Literal_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Value_Duplicate then
            Model.Enumeration_Duplicate_Value_Total :=
              Model.Enumeration_Duplicate_Value_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Value_Static_Required then
            Model.Enumeration_Static_Error_Total :=
              Model.Enumeration_Static_Error_Total + 1;
         elsif Info.Status = Representation_Legality_Enumeration_Incomplete then
            Model.Enumeration_Incomplete_Total := Model.Enumeration_Incomplete_Total + 1;
         end if;
      end if;
   end Count_Enumeration_Result;

   procedure Add_Enumeration_Check
     (Model           : in out Representation_Legality_Model;
      Tree            : Editor.Ada_Syntax_Tree.Tree_Type;
      Static          : Editor.Ada_Static_Expressions.Static_Model;
      Parent_Info     : Representation_Legality_Info;
      Association     : Editor.Ada_Syntax_Tree.Node_Info;
      Literal_Name    : String;
      Value_Text      : String;
      Expected_Pos    : Natural;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id) is
      Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Value_Text);
      Info : Enumeration_Representation_Legality_Info;
      Literal_Pos : Natural := 0;
   begin
      Info.Clause_Node := Association.Id;
      Info.Parent_Clause := Parent_Info.Clause_Node;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Literal_Name := To_Unbounded_String (Trimmed (Literal_Name));
      Info.Normalized_Literal := To_Unbounded_String (Lower (Literal_Name));
      Info.Value_Text := To_Unbounded_String (Trimmed (Value_Text));
      Info.Value_Status := Value_Status_For (Value);
      Info.Static_Value := Value.Integer_Value;
      Info.Expected_Position := Expected_Pos;
      Info.Source_Line := Association.Source_Span.Start_Line;

      if not Is_Enumeration_Type_Node (Tree, Target_Type_Node) then
         Info.Status := Representation_Legality_Enumeration_Target_Not_Enumeration;
      elsif not Enumeration_Literal_Exists (Tree, Target_Type_Node, Literal_Name) then
         Info.Status := Representation_Legality_Enumeration_Literal_Unresolved;
      elsif Enumeration_Literal_Duplicate
              (Model, Parent_Info.Clause_Node, To_String (Info.Normalized_Literal))
      then
         Info.Status := Representation_Legality_Enumeration_Literal_Duplicate;
      elsif Info.Value_Status /= Representation_Value_Static_Integer then
         Info.Status := Representation_Legality_Enumeration_Value_Static_Required;
      elsif Enumeration_Value_Duplicate (Model, Parent_Info.Clause_Node, Info.Static_Value) then
         Info.Status := Representation_Legality_Enumeration_Value_Duplicate;
      else
         Literal_Pos := Enumeration_Literal_Position (Tree, Target_Type_Node, Literal_Name);
         if Literal_Pos > 1 then
            for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
               declare
                  Prior : constant Enumeration_Representation_Legality_Info :=
                    Model.Enumeration_Checks (Index);
               begin
                  if Prior.Parent_Clause = Parent_Info.Clause_Node
                    and then Prior.Value_Status = Representation_Value_Static_Integer
                    and then Prior.Expected_Position < Literal_Pos
                    and then Prior.Static_Value >= Info.Static_Value
                  then
                     Info.Status := Representation_Legality_Enumeration_Value_Order;
                     exit;
                  end if;
               end;
            end loop;
         end if;

         if Info.Status = Representation_Legality_Unknown then
            Info.Status := Representation_Legality_Ok;
         end if;
      end if;

      Info.Fingerprint :=
        Mix (Natural (Info.Clause_Node),
             Mix (Natural (Info.Parent_Clause),
                  Mix (Info.Source_Line,
                       Mix (Representation_Legality_Status'Pos (Info.Status),
                            Natural (abs Info.Static_Value mod 2_147_483_647)))));
      Model.Enumeration_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Enumeration_Result (Model, Info);
   end Add_Enumeration_Check;

   procedure Add_Enumeration_Incomplete_Check
     (Model           : in out Representation_Legality_Model;
      Parent_Info     : Representation_Legality_Info;
      Missing_Literal  : String;
      Source_Line      : Positive) is
      Info : Enumeration_Representation_Legality_Info;
   begin
      Info.Parent_Clause := Parent_Info.Clause_Node;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Literal_Name := To_Unbounded_String (Missing_Literal);
      Info.Normalized_Literal := To_Unbounded_String (Lower (Missing_Literal));
      Info.Status := Representation_Legality_Enumeration_Incomplete;
      Info.Source_Line := Source_Line;
      Info.Fingerprint :=
        Mix (Natural (Info.Parent_Clause),
             Mix (Info.Source_Line,
                  Representation_Legality_Status'Pos (Info.Status)));
      Model.Enumeration_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Enumeration_Result (Model, Info);
   end Add_Enumeration_Incomplete_Check;

   procedure Add_Enumeration_Representation_Checks
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Clause   : Editor.Ada_Syntax_Tree.Node_Info;
      Parent_Info : Representation_Legality_Info) is
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Positional_Index : Positive := 1;
   begin
      if Parent_Info.Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Target_Type_Node := Editor.Ada_Type_Graph.Type_Node (Types, Parent_Info.Target_Type).Node;
      end if;

      for C in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Clause.Id) loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Clause.Id, C);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
               declare
                  Selector_Text : constant String :=
                    Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Statement_Target);
                  Action_Text : constant String :=
                    Child_Label (Tree, Child.Id, Editor.Ada_Syntax_Tree.Node_Statement_Action);
                  Is_Named : constant Boolean := Action_Text /= "";
                  Literal_Name : constant String :=
                    (if Is_Named then Selector_Text
                     else Enumeration_Literal_Name_At (Tree, Target_Type_Node, Positional_Index));
                  Value_Text : constant String :=
                    (if Is_Named then Action_Text else Selector_Text);
                  Expected_Pos : constant Natural :=
                    (if Is_Named then Enumeration_Literal_Position (Tree, Target_Type_Node, Selector_Text)
                     else Natural (Positional_Index));
               begin
                  Add_Enumeration_Check
                    (Model, Tree, Static, Parent_Info, Child, Literal_Name,
                     Value_Text, Expected_Pos, Target_Type_Node);
                  if not Is_Named then
                     Positional_Index := Positional_Index + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      if Is_Enumeration_Type_Node (Tree, Target_Type_Node) then
         declare
            Total : constant Natural := Enumeration_Literal_Count (Tree, Target_Type_Node);
         begin
            for Pos in 1 .. Total loop
               declare
                  Lit : constant String := Enumeration_Literal_Name_At (Tree, Target_Type_Node, Pos);
               begin
                  if not Enumeration_Literal_Duplicate
                           (Model, Parent_Info.Clause_Node, Lower (Lit))
                  then
                     Add_Enumeration_Incomplete_Check
                       (Model, Parent_Info, Lit, Clause.Source_Span.Start_Line);
                  end if;
               end;
            end loop;
         end;
      end if;
   end Add_Enumeration_Representation_Checks;

end Editor.Ada_Representation_Legality.Enumeration_Checks;
