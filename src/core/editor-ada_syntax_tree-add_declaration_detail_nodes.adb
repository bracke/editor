with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

separate (Editor.Ada_Syntax_Tree)
   procedure Add_Declaration_Detail_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String;
      Kind   : Node_Kind)
   is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Name  : Unbounded_String := Null_Unbounded_String;
      After_Colon : Unbounded_String := Null_Unbounded_String;
   begin
      case Kind is
         when Node_Package_Declaration | Node_Package_Body |
              Node_Rename_Declaration | Node_Instantiation =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "package"));
         when Node_Subprogram_Declaration | Node_Subprogram_Body |
              Node_Abstract_Subprogram_Declaration |
              Node_Null_Procedure_Declaration |
              Node_Expression_Function_Declaration |
              Node_Formal_Subprogram_Declaration | Node_Body_Stub =>
            if Starts_With_Word (L, "function")
              or else Starts_With_Word (L, "procedure")
            then
               Name := To_Unbounded_String (Subprogram_Name_Text (Clean));
            else
               Name := To_Unbounded_String (Declaration_Name_Text (Clean));
            end if;
         when Node_Type_Declaration | Node_Incomplete_Type_Declaration |
              Node_Private_Extension_Declaration | Node_Formal_Type_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "type"));
         when Node_Subtype_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "subtype"));
         when Node_Task_Declaration | Node_Task_Type_Declaration |
              Node_Single_Task_Declaration | Node_Task_Body |
              Node_Protected_Declaration | Node_Protected_Type_Declaration |
              Node_Single_Protected_Declaration | Node_Protected_Body |
              Node_Entry_Declaration | Node_Entry_Body | Node_Entry_Body_Stub =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean));
         when Node_Object_Declaration | Node_Constant_Declaration |
              Node_Deferred_Constant_Declaration | Node_Number_Declaration |
              Node_Component_Declaration | Node_Discriminant_Specification |
              Node_Parameter_Specification | Node_Formal_Object_Declaration |
              Node_Exception_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean));
         when Node_Formal_Package_Declaration =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "with package"));
         when Node_Choice_Parameter_Specification =>
            Name := To_Unbounded_String (Declaration_Name_Text (Clean, "when"));
         when Node_Enumeration_Literal_Declaration =>
            Name := To_Unbounded_String (Clean);
         when others =>
            null;
      end case;

      if To_String (Name) /= "" then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Name, To_String (Name));
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
      then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Profile,
            Subprogram_Profile_Text (Clean));
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Result,
            Subprogram_Result_Text (Clean));
      end if;

      if Kind = Node_Rename_Declaration and then Contains (L, " renames ") then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Target,
            Segment_After (Clean, "renames"));
      end if;

      if Kind = Node_Entry_Body then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Profile,
                          Segment_Between_First_Parens (Clean));
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Statement_Condition,
                          Segment_Before (Segment_After (Clean, "when"), "is"));
      elsif Kind = Node_Entry_Body_Stub then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Profile,
                          Segment_Between_First_Parens (Clean));
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "entry body stub");
      end if;

      if Kind = Node_Abstract_Subprogram_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "abstract");
      elsif Kind = Node_Null_Procedure_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "null procedure");
      elsif Kind = Node_Expression_Function_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "expression function");
      elsif Kind = Node_Constant_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "constant");
      elsif Kind = Node_Deferred_Constant_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "deferred constant");
      elsif Kind = Node_Number_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "named number");
      elsif Kind = Node_Task_Type_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "task type");
      elsif Kind = Node_Single_Task_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "single task");
      elsif Kind = Node_Protected_Type_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "protected type");
      elsif Kind = Node_Single_Protected_Declaration then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "single protected");
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
        or else Kind = Node_Entry_Body
        or else Kind = Node_Entry_Body_Stub
      then
         null;
      elsif Contains (Clean, ":") then
         After_Colon := To_Unbounded_String (Trim (Segment_After (Clean, ":")));
         if Contains (To_String (After_Colon), ":=") then
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Subtype,
               Segment_Before (To_String (After_Colon), ":="));
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Default,
               Segment_After (To_String (After_Colon), ":="));
         elsif To_String (After_Colon) /= "" then
            Add_Detail_Node
              (Tree, Parent, Depth, Line, Node_Declaration_Subtype, To_String (After_Colon));
         end if;
      elsif Contains (L, " is ") then
         Add_Detail_Node
           (Tree, Parent, Depth, Line, Node_Declaration_Subtype,
            Segment_After (Clean, " is "));
      end if;

      if Kind = Node_Subprogram_Declaration
        or else Kind = Node_Subprogram_Body
        or else Kind = Node_Abstract_Subprogram_Declaration
        or else Kind = Node_Null_Procedure_Declaration
        or else Kind = Node_Expression_Function_Declaration
        or else Kind = Node_Formal_Subprogram_Declaration
        or else Kind = Node_Body_Stub
        or else Kind = Node_Entry_Body
        or else Kind = Node_Entry_Body_Stub
      then
         null;
      elsif Contains (L, " in out ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "in out");
      elsif Contains (L, " out ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "out");
      elsif Contains (L, " in ") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "in");
      elsif Contains (L, " access ") or else Starts_With_Word (L, "access") then
         Add_Detail_Node (Tree, Parent, Depth, Line, Node_Declaration_Mode, "access");
      end if;
   end Add_Declaration_Detail_Nodes;
