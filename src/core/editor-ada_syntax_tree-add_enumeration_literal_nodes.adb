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
   procedure Add_Enumeration_Literal_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Items : constant String := Segment_Between_First_Parens_After (Clean, " is ");
      Start : Natural;
      Level : Natural := 0;

      function Looks_Like_Enumeration_Type return Boolean is
      begin
         return Starts_With_Word (L, "type")
           and then Contains (L, " is ")
           and then Items /= ""
           and then not Contains (L, " range ")
           and then not Contains (L, " digits ")
           and then not Contains (L, " delta ")
           and then not Contains (L, " access ")
           and then not Contains (L, " array ")
           and then not Contains (L, " record")
           and then not Contains (L, " interface")
           and then not Contains (L, " private");
      end Looks_Like_Enumeration_Type;

      procedure Add_Item (Raw : String) is
         Item : constant String := Trim (Raw);
      begin
         if Item /= "" then
            declare
               Ignored : constant Node_Id := Add_Node
                 (Tree, Node_Enumeration_Literal_Declaration,
                  (Line, 1, Line, Last_Column_For (Item)), Parent, Depth, Item);
            begin
               null;
            end;
         end if;
      end Add_Item;
   begin
      if not Looks_Like_Enumeration_Type then
         return;
      end if;

      Start := Items'First;
      for I in Items'Range loop
         if Items (I) = '(' then
            Level := Level + 1;
         elsif Items (I) = ')' and then Level > 0 then
            Level := Level - 1;
         elsif Items (I) = ',' and then Level = 0 then
            if I > Start then
               Add_Item (Items (Start .. I - 1));
            end if;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Items'Last then
         Add_Item (Items (Start .. Items'Last));
      end if;
   end Add_Enumeration_Literal_Nodes;
