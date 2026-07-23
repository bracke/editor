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
   function Opening_Target_Text (Kind : Node_Kind; Label : String) return String is
      Clean : constant String :=
        (if Kind = Node_Expected_Token then Trim (Label) else Strip_Terminator (Label));
      L     : constant String := Lower (Clean);

      function After_Prefix (Prefix : String) return String is
      begin
         if Clean'Length <= Prefix'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Prefix'Length .. Clean'Last));
      end After_Prefix;

      function First_Name (Text : String) return String is
         Work : constant String := Trim (Text);
         L_Work : constant String := Lower (Work);
      begin
         if Work = "" then
            return "";
         elsif Contains (Work, "(") then
            return Segment_Before (Work, "(");
         elsif Contains (Work, ":") then
            return Segment_Before (Work, ":");
         elsif Contains (L_Work, " return ") then
            return Segment_Before (Work, " return " );
         elsif Contains (L_Work, " is ") then
            return Segment_Before (Work, " is " );
         elsif Work'Length > 3
           and then L_Work (L_Work'Last - 2 .. L_Work'Last) = " is"
         then
            return Trim (Work (Work'First .. Work'Last - 3));
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Work;
         end if;
      end First_Name;
   begin
      case Kind is
         when Node_Package_Body =>
            if Starts_With_Word (L, "package body") then
               return First_Name (After_Prefix ("package body"));
            end if;
         when Node_Package_Declaration =>
            if Starts_With_Word (L, "package") then
               return First_Name (After_Prefix ("package"));
            end if;
         when Node_Subprogram_Body =>
            if Starts_With_Word (L, "procedure") then
               return First_Name (After_Prefix ("procedure"));
            elsif Starts_With_Word (L, "function") then
               return First_Name (After_Prefix ("function"));
            end if;
         when Node_Task_Body =>
            return First_Name (After_Prefix ("task body"));
         when Node_Task_Type_Declaration =>
            return First_Name (After_Prefix ("task type"));
         when Node_Single_Task_Declaration =>
            return First_Name (After_Prefix ("task"));
         when Node_Protected_Body =>
            return First_Name (After_Prefix ("protected body"));
         when Node_Protected_Type_Declaration =>
            return First_Name (After_Prefix ("protected type"));
         when Node_Single_Protected_Declaration =>
            return First_Name (After_Prefix ("protected"));
         when Node_Entry_Body =>
            return First_Name (After_Prefix ("entry"));
         when Node_Accept_Statement =>
            return First_Name (After_Prefix ("accept"));
         when Node_Loop_Statement =>
            if Contains (L, " loop") then
               return Segment_Before (Clean, " loop");
            end if;
         when others =>
            null;
      end case;
      return "";
   end Opening_Target_Text;
