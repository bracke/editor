with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers is

   use Editor.Ada_Syntax_Tree;
   use Editor.Text_Helpers;

   function To_Model_Range
     (R : Editor.Ada_Syntax_Tree.Source_Range)
      return Editor.Ada_Language_Model.Source_Range is
   begin
      return (Start_Line => R.Start_Line,
              Start_Column => R.Start_Column,
              End_Line => R.End_Line,
              End_Column => R.End_Column);
   end To_Model_Range;

   function First_Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
   begin
      return Editor.Ada_Declaration_Parser.Syntax_Tree_Helpers.First_Child_Label
        (Tree, Parent, Kind);
   end First_Child_Label;

   function Source_Index_For
     (Source_Text : String;
      Line        : Positive;
      Column      : Positive) return Natural
   is
      Current_Line : Positive := 1;
      I            : Natural := Source_Text'First;
   begin
      if Source_Text'Length = 0 then
         return 0;
      end if;

      while I <= Source_Text'Last and then Current_Line < Line loop
         if Source_Text (I) = Ada.Characters.Latin_1.LF then
            Current_Line := Current_Line + 1;
         end if;
         I := I + 1;
      end loop;

      if Current_Line /= Line then
         return 0;
      end if;

      return Natural'Min
        (Source_Text'Last, I + Natural (Column) - 1);
   exception
      when Constraint_Error =>
         return 0;
   end Source_Index_For;

   function Full_Declaration_Default_Text
     (Source_Text   : String;
      N             : Editor.Ada_Syntax_Tree.Node_Info;
      Existing_Text : String) return String
   is
      Start_Index : constant Natural :=
        Source_Index_For (Source_Text, N.Source_Span.Start_Line, N.Source_Span.Start_Column);
      Stop_Index  : Natural := 0;
      Assign_Pos  : Natural := 0;
      I           : Natural;
   begin
      if Start_Index = 0 then
         return Existing_Text;
      end if;

      I := Start_Index;
      while I <= Source_Text'Last loop
         if Source_Text (I) = '"' then
            I := I + 1;
            while I <= Source_Text'Last loop
               if Source_Text (I) = '"' then
                  if I < Source_Text'Last and then Source_Text (I + 1) = '"' then
                     I := I + 2;
                  else
                     I := I + 1;
                     exit;
                  end if;
               else
                  I := I + 1;
               end if;
            end loop;
         elsif Source_Text (I) = Character'Val (39)
           and then I + 2 <= Source_Text'Last
           and then Source_Text (I + 2) = Character'Val (39)
         then
            I := I + 3;
         elsif Source_Text (I) = ';' then
            Stop_Index := I - 1;
            exit;
         else
            I := I + 1;
         end if;
      end loop;

      if Stop_Index = 0 or else Stop_Index < Start_Index then
         return Existing_Text;
      end if;

      declare
         Segment : constant String := Source_Text (Start_Index .. Stop_Index);
      begin
         Assign_Pos := Ada.Strings.Fixed.Index (Segment, ":=");
         if Assign_Pos = 0 or else Assign_Pos + 2 > Segment'Last then
            return Existing_Text;
         end if;

         declare
            Full_Default : constant String :=
              Trim (Segment (Assign_Pos + 2 .. Segment'Last));
         begin
            if Full_Default = "" then
               return Existing_Text;
            else
               return Full_Default;
            end if;
         end;
      end;
   exception
      when Constraint_Error =>
         return Existing_Text;
   end Full_Declaration_Default_Text;

   function Is_Declaration_Node
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
   begin
      case Kind is
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Package_Body
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subtype_Declaration
            | Editor.Ada_Syntax_Tree.Node_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Number_Declaration
            | Editor.Ada_Syntax_Tree.Node_Component_Declaration
            | Editor.Ada_Syntax_Tree.Node_Discriminant_Specification
            | Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Exception_Declaration
            | Editor.Ada_Syntax_Tree.Node_Generic_Declaration
            | Editor.Ada_Syntax_Tree.Node_Rename_Declaration
            | Editor.Ada_Syntax_Tree.Node_Instantiation
            | Editor.Ada_Syntax_Tree.Node_Separate_Body
            | Editor.Ada_Syntax_Tree.Node_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Body
            | Editor.Ada_Syntax_Tree.Node_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Declaration
            | Editor.Ada_Syntax_Tree.Node_Entry_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub
            | Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration
            | Editor.Ada_Syntax_Tree.Node_Body_Stub
            | Editor.Ada_Syntax_Tree.Node_Choice_Parameter_Specification
            | Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Declaration_Node;

   function Has_Child_Kind
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean
   is
   begin
      if Parent = Editor.Ada_Syntax_Tree.No_Node then
         return False;
      end if;

      for C in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         if Editor.Ada_Syntax_Tree.Node
              (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, C)).Kind = Kind
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Child_Kind;

   function Has_Ancestor_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Id   : Editor.Ada_Syntax_Tree.Node_Id;
      Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean
   is
      P : Editor.Ada_Syntax_Tree.Node_Id;
   begin
      if Id = Editor.Ada_Syntax_Tree.No_Node then
         return False;
      end if;

      P := Editor.Ada_Syntax_Tree.Node (Tree, Id).Parent;
      while P /= Editor.Ada_Syntax_Tree.No_Node loop
         if Editor.Ada_Syntax_Tree.Node (Tree, P).Kind = Kind then
            return True;
         end if;
         P := Editor.Ada_Syntax_Tree.Node (Tree, P).Parent;
      end loop;
      return False;
   end Has_Ancestor_Kind;

   function Has_Direct_Generic_Parent
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info) return Boolean is
   begin
      return N.Parent /= Editor.Ada_Syntax_Tree.No_Node
        and then Editor.Ada_Syntax_Tree.Node (Tree, N.Parent).Kind =
          Editor.Ada_Syntax_Tree.Node_Generic_Declaration;
   end Has_Direct_Generic_Parent;

end Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
