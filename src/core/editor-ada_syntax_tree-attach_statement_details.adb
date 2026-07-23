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
   procedure Attach_Statement_Details
     (Tree           : in out Tree_Type;
      Stmt           : Node_Id;
      Kind           : Node_Kind;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Strip_Terminator (Text);
      L     : constant String := Lower (Clean);
      Tail  : constant String :=
        (case Kind is
            when Node_Return_Statement  => Segment_After (Clean, "return"),
            when Node_Raise_Statement   => Segment_After (Clean, "raise"),
            when Node_Exit_Statement    => Segment_After (Clean, "exit"),
            when Node_Goto_Statement    => Segment_After (Clean, "goto"),
            when Node_Delay_Statement   => Segment_After (Clean, "delay"),
            when Node_Requeue_Statement => Segment_After (Clean, "requeue"),
            when Node_Abort_Statement   => Segment_After (Clean, "abort"),
            when others                 => "");
   begin
      if Clean = "" then
         return;
      end if;

      if Is_Alternative then
         Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Alternative, Clean);
      end if;

      case Kind is
         when Node_Return_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Action, Tail);
         when Node_Raise_Statement =>
            if Contains (L, " with ") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "with"));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Message,
                  Segment_After (Tail, "with"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Exit_Statement =>
            if Contains (L, " when ") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "when"));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition,
                  Segment_After (Tail, "when"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Goto_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
         when Node_Delay_Statement =>
            if Starts_With_Word (L, "delay until") then
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "until");
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition,
                  Segment_After (Clean, "delay until"));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "relative");
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Condition, Tail);
            end if;
         when Node_Requeue_Statement =>
            if Contains (L, " with abort") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Tail, "with abort"));
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "with abort");
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
            end if;
         when Node_Abort_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Tail);
         when Node_Assignment_Statement =>
            Add_Detail_Node
              (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
               Segment_Before (Clean, ":="));
            Add_Detail_Node
              (Tree, Stmt, Depth + 1, Line, Node_Statement_Action,
               Segment_After (Clean, ":="));
         when Node_Entry_Call_Statement =>
            Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Mode, "entry call");
            if Contains (Clean, "(") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Clean, "("));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Arguments,
                  Segment_After (Clean, "("));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Clean);
            end if;
         when Node_Call_Statement | Node_Accept_Statement | Node_Pragma_Statement =>
            if Contains (Clean, "(") then
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Target,
                  Segment_Before (Clean, "("));
               Add_Detail_Node
                 (Tree, Stmt, Depth + 1, Line, Node_Statement_Arguments,
                  Segment_After (Clean, "("));
            else
               Add_Detail_Node (Tree, Stmt, Depth + 1, Line, Node_Statement_Target, Clean);
            end if;
         when others =>
            null;
      end case;
   end Attach_Statement_Details;
