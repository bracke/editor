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
   procedure Add_Representation_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is
      Clean  : constant String := Strip_Terminator (Text);
      L      : constant String := Lower (Clean);
      Target : Ada.Strings.Unbounded.Unbounded_String := Null_Unbounded_String;
      Item   : Ada.Strings.Unbounded.Unbounded_String := Null_Unbounded_String;
   begin
      if Clean = "" then
         return;
      end if;

      if Starts_With_Word (L, "for") and then Contains (L, " use ") then
         Target := To_Unbounded_String (Segment_Before (Segment_After (Clean, "for"), "use"));
         Item := To_Unbounded_String (Segment_After (Clean, "use"));
      elsif Starts_With_Word (L, "for") and then Contains (L, " at ") then
         Target := To_Unbounded_String (Segment_Before (Segment_After (Clean, "for"), "at"));
         Item := To_Unbounded_String (Segment_After (Clean, "at"));
      end if;

      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Target, To_String (Target));
      Add_Detail_Node
        (Tree, Clause, Depth, Line, Node_Representation_Item, To_String (Item));

      declare
         Item_Text : constant String := To_String (Item);
      begin
         if Contains (Item_Text, "=>")
           or else (Item_Text /= "" and then Item_Text (Item_Text'First) = '(')
         then
            declare
               Assocs : constant String :=
                 (if Segment_Between_First_Parens (Item_Text) /= "" then
                     Segment_Between_First_Parens (Item_Text)
                  else
                     Item_Text);
            begin
               --  Enumeration representation clauses are aggregate-shaped.
               --  Keep both named and positional aggregate associations so the
               --  semantic projection can map positional values to the retained
               --  enumeration literal order instead of losing them as opaque
               --  item text.
               Add_Association_List_Nodes
                 (Tree, Clause, Depth, Line, Assocs, Node_Named_Association);
            end;
         end if;
      end;
   end Add_Representation_Clause_Detail_Nodes;
