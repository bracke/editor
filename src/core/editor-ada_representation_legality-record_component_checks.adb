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

package body Editor.Ada_Representation_Legality.Record_Component_Checks is

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

   function Ancestor_Representation_Clause
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Editor.Ada_Syntax_Tree.Node_Id
     renames Editor.Ada_Representation_Legality.Core_Utilities.Ancestor_Representation_Clause;

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



   function Component_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean is
   begin
      for Index in 1 .. Natural (Model.Component_Checks.Length) loop
         declare
            Prior : constant Record_Component_Legality_Info := Model.Component_Checks (Index);
         begin
            if Prior.Parent_Clause = Parent_Clause
              and then To_String (Prior.Normalized_Component) = Normalized_Name
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Component_Duplicate;

   procedure Count_Component_Result
     (Model : in out Representation_Legality_Model;
      Info  : Record_Component_Legality_Info) is
   begin
      if Info.Status /= Representation_Legality_Ok then
         Model.Component_Error_Total := Model.Component_Error_Total + 1;
         if Info.Status = Representation_Legality_Record_Component_Duplicate then
            Model.Component_Duplicate_Total := Model.Component_Duplicate_Total + 1;
         elsif Info.Status in Representation_Legality_Record_Component_Static_Value_Required |
                              Representation_Legality_Record_Component_Bit_Range_Reversed |
                              Representation_Legality_Record_Component_Negative_Position
         then
            Model.Component_Static_Error_Total := Model.Component_Static_Error_Total + 1;
         end if;
      end if;
   end Count_Component_Result;

   procedure Add_Record_Component_Check
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Node     : Editor.Ada_Syntax_Tree.Node_Info) is
      Parent_Clause : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Ancestor_Representation_Clause (Tree, Node.Id);
      Parent_Info : constant Representation_Legality_Info :=
        Check_For_Clause (Model, Parent_Clause);
      Component_Text : constant String :=
        Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Target);
      Storage_Text : constant String :=
        Strip_Leading_At (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Item));
      Range_Text : constant String :=
        Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Range_Expression);
      First_Text : constant String := Range_First (Range_Text);
      Last_Text  : constant String := Range_Last (Range_Text);
      Storage_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Storage_Text);
      First_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, First_Text);
      Last_Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Static, Editor.Ada_Declarative_Regions.No_Region, Last_Text);
      Info : Record_Component_Legality_Info;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      Info.Clause_Node := Node.Id;
      Info.Parent_Clause := Parent_Clause;
      Info.Target_Name := Parent_Info.Target_Name;
      Info.Component_Name := To_Unbounded_String (Trimmed (Component_Text));
      Info.Normalized_Component := To_Unbounded_String (Lower (Component_Text));
      Info.Storage_Unit_Text := To_Unbounded_String (Storage_Text);
      Info.First_Bit_Text := To_Unbounded_String (First_Text);
      Info.Last_Bit_Text := To_Unbounded_String (Last_Text);
      Info.Storage_Value_Status := Value_Status_For (Storage_Value);
      Info.First_Bit_Value_Status := Value_Status_For (First_Value);
      Info.Last_Bit_Value_Status := Value_Status_For (Last_Value);
      Info.Static_Storage_Unit := Storage_Value.Integer_Value;
      Info.Static_First_Bit := First_Value.Integer_Value;
      Info.Static_Last_Bit := Last_Value.Integer_Value;
      Info.Source_Line := Node.Source_Span.Start_Line;

      if Parent_Info.Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Target_Type_Node := Editor.Ada_Type_Graph.Type_Node (Types, Parent_Info.Target_Type).Node;
      end if;

      if Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Record
        and then Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Private
        and then Parent_Info.Target_Category /= Editor.Ada_Type_Graph.Type_Category_Unknown
      then
         Info.Status := Representation_Legality_Target_Kind_Mismatch;
      elsif not Has_Record_Component (Tree, Target_Type_Node, Component_Text) then
         Info.Status := Representation_Legality_Record_Component_Unresolved;
      elsif Component_Duplicate (Model, Parent_Clause, To_String (Info.Normalized_Component)) then
         Info.Status := Representation_Legality_Record_Component_Duplicate;
      elsif Info.Storage_Value_Status /= Representation_Value_Static_Integer
        or else Info.First_Bit_Value_Status /= Representation_Value_Static_Integer
        or else Info.Last_Bit_Value_Status /= Representation_Value_Static_Integer
      then
         Info.Status := Representation_Legality_Record_Component_Static_Value_Required;
      elsif Info.Static_Storage_Unit < 0
        or else Info.Static_First_Bit < 0
        or else Info.Static_Last_Bit < 0
      then
         Info.Status := Representation_Legality_Record_Component_Negative_Position;
      elsif Info.Static_Last_Bit < Info.Static_First_Bit then
         Info.Status := Representation_Legality_Record_Component_Bit_Range_Reversed;
      else
         Info.Status := Representation_Legality_Ok;
      end if;

      Info.Fingerprint :=
        Mix (Natural (Info.Clause_Node),
             Mix (Natural (Info.Parent_Clause),
                  Mix (Info.Source_Line,
                       Mix (Representation_Legality_Status'Pos (Info.Status),
                            Mix (Natural (abs Info.Static_Storage_Unit mod 2_147_483_647),
                                 Natural (abs Info.Static_First_Bit mod 2_147_483_647))))));

      Model.Component_Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Count_Component_Result (Model, Info);
   end Add_Record_Component_Check;

end Editor.Ada_Representation_Legality.Record_Component_Checks;
