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
   procedure Add_Association_List_Nodes
     (Tree             : in out Tree_Type;
      Parent           : Node_Id;
      Depth            : Natural;
      Line             : Positive;
      Text             : String;
      Association_Kind : Node_Kind)
   is
      Clean     : constant String := Strip_Terminator (Text);
      Start     : Natural;
      Level     : Natural := 0;
      In_String : Boolean := False;
      I         : Natural;

      procedure Add_Association (Raw : String) is
         Segment : constant String := Strip_Terminator (Raw);
         Assoc   : Node_Id;

         procedure Add_Key_Value_Details
           (Key_Node   : Node_Kind;
            Value_Node : Node_Kind)
         is
            Key   : constant String := Split_Before_Top_Level_Arrow (Segment);
            Value : constant String := Split_After_Top_Level_Arrow (Segment);
         begin
            if Has_Top_Level_Arrow (Segment) then
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Key_Node, Key);
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Value_Node, Value);
            else
               Add_Detail_Node (Tree, Assoc, Depth + 1, Line, Value_Node, Segment);
            end if;
         end Add_Key_Value_Details;
      begin
         if Segment = "" then
            return;
         end if;

         Assoc := Add_Node
           (Tree, Association_Kind, (Line, 1, Line, Last_Column_For (Segment)),
            Parent, Depth, Segment);

         case Association_Kind is
            when Node_Aspect_Association =>
               Add_Key_Value_Details (Node_Aspect_Name, Node_Aspect_Value);
            when Node_Generic_Actual_Association =>
               Add_Key_Value_Details (Node_Generic_Actual_Formal, Node_Generic_Actual_Value);
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target,
                     Split_Before_Top_Level_Arrow (Segment));
               end if;
            when Node_Discriminant_Specification | Node_Parameter_Specification =>
               Add_Declaration_Detail_Nodes (Tree, Assoc, Depth + 1, Line, Segment, Association_Kind);
            when Node_Pragma_Argument =>
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Pragma_Argument_Association, Segment);
                  Add_Key_Value_Details (Node_Statement_Target, Node_Statement_Action);
               else
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Arguments, Segment);
               end if;
            when others =>
               if Has_Top_Level_Arrow (Segment) then
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target,
                     Split_Before_Top_Level_Arrow (Segment));
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Action,
                     Split_After_Top_Level_Arrow (Segment));
               else
                  Add_Detail_Node
                    (Tree, Assoc, Depth + 1, Line, Node_Statement_Target, Segment);
               end if;
         end case;
      end Add_Association;
   begin
      if Clean = "" then
         return;
      end if;

      Start := Clean'First;
      I := Clean'First;
      while I <= Clean'Last loop
         if In_String then
            if Clean (I) = '"' then
               if I + 1 <= Clean'Last and then Clean (I + 1) = '"' then
                  I := I + 1;
               else
                  In_String := False;
               end if;
            end if;
         elsif Is_Character_Literal_At (Clean, I, Clean'Last) then
            I := I + 2;
         elsif Clean (I) = '"' then
            In_String := True;
         elsif Clean (I) = '(' then
            Level := Level + 1;
         elsif Clean (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Clean (I) = ',' and then Level = 0 then
            if I > Start then
               Add_Association (Clean (Start .. I - 1));
            end if;
            Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      if Start <= Clean'Last then
         Add_Association (Clean (Start .. Clean'Last));
      end if;
   end Add_Association_List_Nodes;
