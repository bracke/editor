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
   procedure Add_Action_Sequence
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is
      Clean : constant String := Trim (Text);
      Seq   : Node_Id;
      Start : Natural;
      Semi  : Natural;

      procedure Add_Action_Segment (Raw_Segment : String) is
         Segment : constant String := Trim (Raw_Segment);
         L       : constant String := Lower (Segment);
      begin
         if Segment = "" or else Starts_With_Word (L, "end") then
            return;
         elsif Starts_With_Word (L, "when") and then Contains (L, "=>") then
            Add_Detail_Node
              (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Segment, "when"), "=>"));
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "=>"), True);
         elsif Starts_With_Word (L, "else") then
            Add_Detail_Node (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative, "else");
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "else"), True);
         elsif Starts_With_Word (L, "elsif") then
            Add_Detail_Node
              (Tree, Seq, Depth + 1, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Segment, "elsif"), "then"));
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, True);
         elsif Starts_With_Word (L, "then") and then Contains (L, "then abort") then
            Add_Detail_Node (Tree, Seq, Depth + 1, Line, Node_Statement_Mode, "then abort");
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment_After (Segment, "then abort"), True);
         elsif Starts_With_Word (L, "or") then
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, True);
         else
            Add_Structured_Statement_Node
              (Tree, Seq, Depth + 1, Line, Segment, Is_Alternative);
         end if;
      end Add_Action_Segment;
   begin
      if Clean = "" then
         return;
      end if;

      Seq := Add_Node
        (Tree, Node_Statement_Sequence,
         (Line, 1, Line, Last_Column_For (Clean)), Parent, Depth, Clean);

      Start := Clean'First;
      while Start <= Clean'Last loop
         Semi := 0;
         for I in Start .. Clean'Last loop
            if Clean (I) = ';' then
               Semi := I;
               exit;
            end if;
         end loop;

         if Semi = 0 then
            Add_Action_Segment (Clean (Start .. Clean'Last));
            exit;
         elsif Semi > Start then
            Add_Action_Segment (Clean (Start .. Semi));
            Start := Semi + 1;
         else
            Start := Start + 1;
         end if;
      end loop;
   end Add_Action_Sequence;
