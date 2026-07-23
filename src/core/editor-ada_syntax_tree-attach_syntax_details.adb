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
   procedure Attach_Syntax_Details
     (Tree   : in out Tree_Type;
      Id     : Node_Id;
      Kind   : Node_Kind;
      Code   : String;
      Line   : Positive;
      Depth  : Natural)
   is
      L : constant String := Lower (Code);
      Semi : Natural;
   begin
      Add_Header_Recovery_Details (Tree, Id, Depth, Line, Kind, Code);
      case Kind is
         when Node_Package_Declaration
            | Node_Package_Body
            | Node_Subprogram_Declaration
            | Node_Abstract_Subprogram_Declaration
            | Node_Null_Procedure_Declaration
            | Node_Expression_Function_Declaration
            | Node_Subprogram_Body
            | Node_Type_Declaration
            | Node_Subtype_Declaration
            | Node_Object_Declaration
            | Node_Constant_Declaration
            | Node_Deferred_Constant_Declaration
            | Node_Number_Declaration
            | Node_Component_Declaration
            | Node_Discriminant_Specification
            | Node_Parameter_Specification
            | Node_Formal_Object_Declaration
            | Node_Formal_Type_Declaration
            | Node_Formal_Subprogram_Declaration
            | Node_Exception_Declaration
            | Node_Generic_Declaration
            | Node_Rename_Declaration
            | Node_Separate_Body
            | Node_Task_Declaration
            | Node_Task_Type_Declaration
            | Node_Single_Task_Declaration
            | Node_Task_Body
            | Node_Protected_Declaration
            | Node_Protected_Type_Declaration
            | Node_Single_Protected_Declaration
            | Node_Protected_Body
            | Node_Entry_Declaration
            | Node_Entry_Body
            | Node_Entry_Body_Stub
            | Node_Private_Part
            | Node_Incomplete_Type_Declaration
            | Node_Private_Extension_Declaration
            | Node_Body_Stub
            | Node_Choice_Parameter_Specification
            | Node_Enumeration_Literal_Declaration =>
            Add_Declaration_Detail_Nodes (Tree, Id, Depth, Line, Code, Kind);
            if Kind = Node_Type_Declaration
              or else Kind = Node_Private_Extension_Declaration
            then
               Add_Discriminant_Nodes (Tree, Id, Depth, Line, Code);
               Add_Enumeration_Literal_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Kind = Node_Type_Declaration or else Kind = Node_Subtype_Declaration or else Kind = Node_Private_Extension_Declaration then
               Add_Expression_Nodes (Tree, Id, Depth, Line, Code);
            elsif Kind = Node_Object_Declaration
              or else Kind = Node_Constant_Declaration
              or else Kind = Node_Deferred_Constant_Declaration
              or else Kind = Node_Number_Declaration
            then
               Add_Expression_Nodes (Tree, Id, Depth, Line, Segment_Before (Code, ":"));
               if Contains (Code, ":=") then
                  Add_Expression_Nodes (Tree, Id, Depth, Line, Segment_After (Code, ":="));
               end if;
            end if;
         when Node_Instantiation =>
            Add_Generic_Actual_Part_Nodes (Tree, Id, Depth, Line, Code);
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
         when Node_Formal_Package_Declaration =>
            Add_Declaration_Detail_Nodes (Tree, Id, Depth, Line, Code, Kind);
            --  Formal package declarations have the same association-list
            --  grammar as ordinary generic actual parts, but they are generic
            --  formal declarations rather than instantiations:
            --     with package P is new G (A => B, others => <>);
            --  Retain the actual-part nodes under the formal package symbol so
            --  language-model projection can expose named actual selectors,
            --  box defaults, and duplicate/ordering diagnostics without
            --  treating the generic package name itself as an expression.
            if Trim (Segment_Between_First_Parens (Code)) /= "<>" then
               Add_Generic_Actual_Part_Nodes (Tree, Id, Depth, Line, Code);
            end if;
            if Contains (L, " with ") then
               Add_Aspect_Specification_Nodes (Tree, Id, Depth, Line, Code);
            end if;
         when Node_Aspect_Specification =>
            Add_Association_List_Nodes
              (Tree, Id, Depth, Line, Strip_Leading_With (Code), Node_Aspect_Association);
         when Node_Generic_Actual_Part =>
            declare
               Actuals : constant String :=
                 (if Segment_Between_First_Parens (Code) /= "" then
                    Segment_Between_First_Parens (Code)
                  else
                    Code);
            begin
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Actuals, Node_Generic_Actual_Association);
            end;
         when Node_Representation_Clause =>
            Add_Representation_Clause_Detail_Nodes (Tree, Id, Depth, Line, Code);
         when Node_Representation_Component_Clause =>
            Add_Representation_Component_Clause_Detail_Nodes (Tree, Id, Depth, Line, Code);
         when Node_Representation_Mod_Clause =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Representation_Item,
               Segment_After (Code, "mod"));
         when Node_Variant_Part =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Selector,
               Segment_Before (Segment_After (Code, "case"), "is"));
         when Node_Variant =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            declare
               Decls : constant String := Segment_After (Code, "=>");
               Start : Natural := Decls'First;
               Semi  : Natural;
            begin
               while Decls /= "" and then Start <= Decls'Last loop
                  Semi := 0;
                  for I in Start .. Decls'Last loop
                     if Decls (I) = ';' then
                        Semi := I;
                        exit;
                     end if;
                  end loop;
                  declare
                     Piece : constant String :=
                       Trim (if Semi = 0 then Decls (Start .. Decls'Last) else Decls (Start .. Semi));
                  begin
                     if Piece /= "" and then Contains (Piece, ":") then
                        declare
                           Component : constant Node_Id := Add_Node
                             (Tree, Node_Component_Declaration,
                              (Line, 1, Line, Last_Column_For (Piece)), Id, Depth + 1, Piece);
                        begin
                           Add_Declaration_Detail_Nodes
                             (Tree, Component, Depth + 2, Line, Piece, Node_Component_Declaration);
                        end;
                     elsif Piece /= "" then
                        Add_Action_Sequence (Tree, Id, Depth, Line, Piece, True);
                     end if;
                  end;
                  exit when Semi = 0;
                  Start := Semi + 1;
               end loop;
            end;
         when Node_If_Statement =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               If_Condition_Text (Code, "if"));
            declare
               Tail : constant String := If_Action_Text (Code);
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Elsif_Part =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               If_Condition_Text (Code, "elsif"));
            declare
               Tail : constant String := If_Action_Text (Code);
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Else_Part =>
            if First_Semicolon (Segment_After (Code, "else")) /= 0 then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "else"), True);
            end if;
         when Node_Case_Statement =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Selector,
               Segment_Before (Segment_After (Code, "case"), "is"));
            if Contains (L, "=>") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
            end if;
         when Node_When_Alternative =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Action_Sequence
              (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
         when Node_Select_Alternative =>
            if Starts_With_Word (L, "then") and then Contains (L, "then abort") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "then abort");
               declare
                  Tail : constant String := Segment_After (Code, "then abort");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            elsif Starts_With_Word (L, "else") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Alternative, "else");
               declare
                  Tail : constant String := Segment_After (Code, "else");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            elsif Starts_With_Word (L, "terminate") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "terminate");
            else
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Alternative, "or");
               declare
                  Tail : constant String := Segment_After (Code, "or");
               begin
                  if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                     Add_Action_Sequence
                       (Tree, Id, Depth, Line, Tail, True);
                  end if;
               end;
            end if;
         when Node_Exception_Handler =>
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Alternative,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Detail_Node
              (Tree, Id, Depth, Line, Node_Statement_Condition,
               Segment_Before (Segment_After (Code, "when"), "=>"));
            Add_Action_Sequence
              (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
         when Node_Exception_Section =>
            if Contains (L, " when ") and then Contains (L, "=>") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Alternative,
                  Segment_Before (Segment_After (Code, "when"), "=>"));
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "=>"), True);
            end if;
         when Node_Loop_Statement =>
            if Starts_With_Word (L, "while") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Condition,
                  Segment_Before (Segment_After (Code, "while"), "loop"));
            elsif Starts_With_Word (L, "for") then
               Add_Detail_Node
                 (Tree, Id, Depth, Line, Node_Statement_Selector,
                  Segment_Before (Segment_After (Code, "for"), "loop"));
            end if;
            declare
               Tail : constant String := Segment_After (Code, "loop");
            begin
               if Tail /= "" and then not Starts_With_Word (Lower (Tail), "end") then
                  Add_Action_Sequence
                    (Tree, Id, Depth, Line, Tail);
               end if;
            end;
         when Node_Declare_Block =>
            if Contains (L, " begin ") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "begin"));
            end if;
         when Node_Begin_Block =>
            if First_Semicolon (Segment_After (Code, "begin")) /= 0 then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "begin"));
            end if;
         when Node_Select_Statement =>
            if Contains (L, " then abort ") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "triggering");
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Segment_Before (Code, "then abort"), "select"));
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "then abort");
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "then abort"), True);
            elsif Contains (L, " terminate") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Mode, "terminate");
            elsif Starts_With_Word (L, "select") then
               Add_Action_Sequence
                 (Tree, Id, Depth, Line, Segment_After (Code, "select"));
            end if;
         when Node_Accept_Statement =>
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
            if Contains (L, " do ") then
               Add_Action_Sequence (Tree, Id, Depth, Line, Segment_After (Code, "do"));
            end if;
         when Node_Pragma_Statement =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Pragma_Name, Segment_Before (Code, "("));
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
            if Contains (Code, "(") then
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Segment_Between_First_Parens (Code), Node_Pragma_Argument);
            end if;
         when Node_Return_Statement
            | Node_Raise_Statement
            | Node_Exit_Statement
            | Node_Goto_Statement
            | Node_Requeue_Statement
            | Node_Delay_Statement
            | Node_Abort_Statement
            | Node_Terminate_Statement
            | Node_Assignment_Statement
            | Node_Entry_Call_Statement
            | Node_Call_Statement
            | Node_Null_Statement =>
            Attach_Statement_Details (Tree, Id, Kind, Depth - 1, Line, Code);
         when Node_Pragma =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Pragma_Name, Segment_Before (Code, "("));
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Target, Segment_Before (Code, "("));
            if Contains (Code, "(") then
               Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Arguments, Segment_After (Code, "("));
               Add_Association_List_Nodes
                 (Tree, Id, Depth, Line, Segment_Between_First_Parens (Code), Node_Pragma_Argument);
            end if;
         when Node_Label =>
            Add_Detail_Node (Tree, Id, Depth, Line, Node_Statement_Target, Code);
            Add_Name_Tokens (Tree, Id, Depth, Line, Code);
         when Node_End =>
            declare
               Target : constant String := End_Target_Text (Code);
               Parent : constant Node_Id := Node (Tree, Id).Parent;
            begin
               if Target /= "" then
                  Add_Detail_Node (Tree, Id, Depth, Line, Node_End_Target, Target);
               end if;
               if Contains (Lower (Code), " with ")
                 and then Parent /= No_Node
               then
                  Add_Aspect_Specification_Nodes
                    (Tree, Parent, Node (Tree, Parent).Depth + 1, Line, Code);
               end if;
            end;
         when others =>
            null;
      end case;
   end Attach_Syntax_Details;
