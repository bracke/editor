with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor;
use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Entry_Parsing is
   use Editor.Ada_Token_Cursor.Tokenization;

   function Current_Lower (Position : Cursor) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower;

   function Lookahead_Lower
     (Position : Cursor;
      Offset   : Natural) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   function Parenthesized_Has_Top_Level_Token
     (Position : Cursor;
      Text     : String) return Boolean
     renames Editor.Ada_Token_Cursor.Range_Structure_Helpers.Parenthesized_Has_Top_Level_Token;

   procedure Parse_Parameter_Profile
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Parameter_Profile;

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info) is
      First_Is_Family : Boolean := False;

      procedure Skip_One_Parenthesized_Group is
         Depth : Natural := 0;
      begin
         while not At_End (Position) loop
            declare
               T : constant String := To_String (Current (Position).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth <= 1 then
                     Advance (Position);
                     return;
                  else
                     Depth := Depth - 1;
                  end if;
               end if;
               Advance (Position);
            end;
         end loop;
      end Skip_One_Parenthesized_Group;
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      if Lookahead_Lower (Position, 1) = "for" then
         Add_Production
           (Result, Production_Entry_Index_Specification, Tok,
            "entry index specification");
         Add_Production
           (Result, Production_Entry_Body_Index_Identifier, Tok,
            "entry body index identifier");
         Add_Production
           (Result, Production_Entry_Body_Index_Subtype, Tok,
            "entry body index subtype");
         Skip_One_Parenthesized_Group;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = "("
         then
            Add_Production
              (Result, Production_Entry_Parameter_Profile, Current (Position),
               "entry parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
      else
         First_Is_Family :=
           not Parenthesized_Has_Top_Level_Token (Position, ":")
           and then not Parenthesized_Has_Top_Level_Token (Position, ";")
           and then Lookahead_Lower (Position, 1) /= "in"
           and then Lookahead_Lower (Position, 1) /= "out";

         if First_Is_Family then
            declare
               Mark_Pos : constant Natural := Mark (Position);
               Family_Is_Empty : constant Boolean :=
                 To_String (Current (Position).Text) = "("
                 and then Lookahead_Lower (Position, 1) = ")";
               Family_Has_Range : constant Boolean :=
                 Parenthesized_Has_Top_Level_Token (Position, "..")
                 or else Parenthesized_Has_Top_Level_Token (Position, "range");
            begin
               Skip_One_Parenthesized_Group;

               if Family_Is_Empty then
                  Add_Production
                    (Result,
                     Production_Entry_Family_Empty_Definition_Recovery_Boundary,
                     Tok, "entry family empty definition recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected entry family discrete subtype definition");
               end if;

               if To_String (Current (Position).Text) = "(" then
                  Add_Production
                    (Result, Production_Entry_Family_Definition, Tok,
                     "entry family definition");
                  Add_Production
                    (Result,
                     Production_Entry_Family_Discrete_Subtype_Definition,
                     Tok, "entry family discrete subtype definition");
                  Add_Production
                    (Result, Production_Entry_Family_Index_Subtype,
                     Tok, "entry family index subtype");
                  if Family_Has_Range then
                     Add_Production
                       (Result, Production_Entry_Family_Range_Definition, Tok,
                        "entry family range definition");
                  end if;
                  Add_Production
                    (Result, Production_Entry_Parameter_Profile,
                     Current (Position), "entry parameter profile");
                  Parse_Parameter_Profile (Position, Result);
               else
                  Add_Production
                    (Result, Production_Entry_Family_Definition, Tok,
                     "entry family definition");
                  if not Family_Is_Empty then
                     Add_Production
                       (Result,
                        Production_Entry_Family_Discrete_Subtype_Definition,
                        Tok, "entry family discrete subtype definition");
                     Add_Production
                       (Result, Production_Entry_Family_Index_Subtype,
                        Tok, "entry family index subtype");
                     if Family_Has_Range then
                        Add_Production
                          (Result, Production_Entry_Family_Range_Definition, Tok,
                           "entry family range definition");
                     end if;
                  end if;
                  Restore (Position, Mark_Pos);
                  Skip_One_Parenthesized_Group;
               end if;
            end;
         else
            Add_Production
              (Result, Production_Entry_Parameter_Profile, Current (Position),
               "entry parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
      end if;
   end Parse_Entry_Parenthesized_Parts;

   procedure Add_Statement_Name_Suffix_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result;
      Start_At : Natural;
      End_At   : Natural;
      For_Assignment : Boolean) is
      Has_Selected        : Boolean := False;
      Has_Paren           : Boolean := False;
      Has_Range           : Boolean := False;
      Has_All             : Boolean := False;
      Has_Arrow           : Boolean := False;
      Has_Selected_Call   : Boolean := False;
      Has_Indexed_Prefix  : Boolean := False;
      Has_Dispatching     : Boolean := False;
      Last_Dot_Index      : Natural := 0;
      First_Paren_Index   : Natural := 0;

      procedure Add_Actual_Part_Delimiter_Productions is
         Depth     : Natural := 0;
         Saw_Open  : Boolean := False;
         Saw_Close : Boolean := False;
         Last_Top_Level_Was_Open      : Boolean := False;
         Last_Top_Level_Was_Separator : Boolean := False;
         Last_Top_Level_Was_Arrow     : Boolean := False;

         procedure Add_Missing_Actual
           (Anchor : Token_Info;
            Reason : String) is
         begin
            Add_Production
              (Result, Production_Call_Actual_Missing_Actual_Recovery_Boundary,
               Anchor, Reason);
            Add_Production
              (Result,
               Production_Entry_Call_Actual_Missing_Actual_Recovery_Boundary,
               Anchor, Reason);
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected call actual association expression");
         end Add_Missing_Actual;

         procedure Add_Trailing_Separator
           (Anchor : Token_Info) is
         begin
            Add_Production
              (Result,
               Production_Call_Actual_Trailing_Separator_Recovery_Boundary,
               Anchor, "call actual trailing separator recovery boundary");
            Add_Production
              (Result,
               Production_Entry_Call_Actual_Trailing_Separator_Recovery_Boundary,
               Anchor, "entry-call actual trailing separator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected call actual after separator");
         end Add_Trailing_Separator;
      begin
         for I in Start_At .. End_At - 1 loop
            declare
               T : constant String :=
                 To_String (Position.Stream.Tokens (Positive (I)).Text);
            begin
               if T = "(" then
                  if not Saw_Open then
                     Saw_Open := True;
                     Depth := 1;
                     Last_Top_Level_Was_Open := True;
                     Last_Top_Level_Was_Separator := False;
                     Last_Top_Level_Was_Arrow := False;
                     Add_Production
                       (Result, Production_Call_Actual_List_Open_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "call actual list opening delimiter");
                     Add_Production
                       (Result, Production_Entry_Call_Actual_List_Open_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "entry-call actual list opening delimiter");
                  else
                     Depth := Depth + 1;
                  end if;
               elsif T = ")" and then Saw_Open then
                  if Depth = 1 then
                     Saw_Close := True;
                     if Last_Top_Level_Was_Open then
                        Add_Production
                          (Result,
                           Production_Call_Actual_Empty_List_Recovery_Boundary,
                           Position.Stream.Tokens (Positive (I)),
                           "call actual empty list recovery boundary");
                        Add_Production
                          (Result,
                           Production_Entry_Call_Actual_Empty_List_Recovery_Boundary,
                           Position.Stream.Tokens (Positive (I)),
                           "entry-call actual empty list recovery boundary");
                        Add_Production
                          (Result, Production_Recovery_Point,
                           Position.Stream.Tokens (Positive (I)),
                           "expected call actual inside actual list");
                     elsif Last_Top_Level_Was_Separator then
                        Add_Trailing_Separator
                          (Position.Stream.Tokens (Positive (I)));
                     elsif Last_Top_Level_Was_Arrow then
                        Add_Missing_Actual
                          (Position.Stream.Tokens (Positive (I)),
                           "call actual association missing expression before close");
                     end if;
                     Add_Production
                       (Result, Production_Call_Actual_List_Close_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "call actual list closing delimiter");
                     Add_Production
                       (Result, Production_Entry_Call_Actual_List_Close_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "entry-call actual list closing delimiter");
                     exit;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif T = "," and then Saw_Open and then Depth = 1 then
                  if Last_Top_Level_Was_Open
                    or else Last_Top_Level_Was_Separator
                    or else Last_Top_Level_Was_Arrow
                  then
                     Add_Missing_Actual
                       (Position.Stream.Tokens (Positive (I)),
                        "call actual association missing expression before separator");
                  end if;
                  Add_Production
                    (Result, Production_Call_Actual_Association_Separator,
                     Position.Stream.Tokens (Positive (I)),
                     "call actual association separator");
                  Add_Production
                    (Result, Production_Entry_Call_Actual_Association_Separator,
                     Position.Stream.Tokens (Positive (I)),
                     "entry-call actual association separator");
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := True;
                  Last_Top_Level_Was_Arrow := False;
               elsif T = "=>" and then Saw_Open and then Depth = 1 then
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := False;
                  Last_Top_Level_Was_Arrow := True;
               elsif Saw_Open and then Depth = 1 then
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := False;
                  Last_Top_Level_Was_Arrow := False;
               end if;
            end;
         end loop;

         if Saw_Open and then not Saw_Close then
            Add_Production
              (Result, Production_Call_Actual_List_Missing_Close_Recovery_Boundary,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "call actual list missing close recovery boundary");
            Add_Production
              (Result, Production_Entry_Call_Actual_List_Missing_Close_Recovery_Boundary,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "entry-call actual list missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "expected closing parenthesis after call actual list");
         end if;
      end Add_Actual_Part_Delimiter_Productions;
   begin
      if End_At <= Start_At + 1 then
         return;
      end if;

      Add_Production
        (Result, Production_Statement_Name_Suffix,
         Position.Stream.Tokens (Positive (Start_At)),
         "statement name suffix");

      for I in Start_At .. End_At - 1 loop
         declare
            T : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Text);
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if T = "." then
               Has_Selected := True;
               Last_Dot_Index := I;
            elsif T = "(" then
               Has_Paren := True;
               if First_Paren_Index = 0 then
                  First_Paren_Index := I;
               end if;
            elsif T = ".." then
               Has_Range := True;
            elsif T = "=>" then
               Has_Arrow := True;
            elsif L = "all" then
               Has_All := True;
            end if;
         end;
      end loop;

      if Has_Selected and then Has_Paren then
         Has_Selected_Call := Last_Dot_Index < First_Paren_Index;
      end if;

      if Has_Selected and then Last_Dot_Index > Start_At then
         Has_Dispatching := True;
      end if;

      if Has_Paren and then First_Paren_Index > Start_At then
         Has_Indexed_Prefix := True;
      end if;

      if For_Assignment then
         if Has_Selected then
            Add_Production
              (Result, Production_Assignment_Selected_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected assignment target");
         end if;
         if Has_Paren then
            Add_Production
              (Result, Production_Assignment_Indexed_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed assignment target");
         end if;
         if Has_Range then
            Add_Production
              (Result, Production_Assignment_Slice_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "slice assignment target");
         end if;
         if Has_All then
            Add_Production
              (Result, Production_Assignment_Dereference_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "dereference assignment target");
         end if;
      else
         if Has_Selected then
            Add_Production
              (Result, Production_Call_Selected_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected call target");
            Add_Production
              (Result, Production_Call_Selected_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected call prefix");
            Add_Production
              (Result, Production_Call_Selected_Operation_Name,
               Position.Stream.Tokens (Positive (Last_Dot_Index + 1)),
               "selected call operation name");
         end if;
         if Has_Dispatching then
            Add_Production
              (Result, Production_Call_Dispatching_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "dispatching-style call prefix");
         end if;
         if Has_Paren then
            Add_Production
              (Result, Production_Call_Indexed_Or_Actual_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed or actual call target");
            Add_Production
              (Result, Production_Call_Actual_List,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "call actual or index list");
            Add_Actual_Part_Delimiter_Productions;
         end if;
         if Has_Indexed_Prefix then
            Add_Production
              (Result, Production_Call_Indexed_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed call prefix");
         end if;
         if Has_Selected_Call and then Has_Paren then
            Add_Production
              (Result, Production_Call_Entry_Family_Ambiguity,
               Position.Stream.Tokens (Positive (Start_At)),
               "entry-family or procedure-call ambiguity");
         end if;
         if Has_Arrow then
            Add_Production
              (Result, Production_Call_Actual_Association,
               Position.Stream.Tokens (Positive (Start_At)),
               "call actual association");
         end if;
      end if;
   end Add_Statement_Name_Suffix_Productions;

   procedure Add_Entry_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe       : Cursor := Position;
      Found_Begin : Boolean := False;
   begin
      while not At_End (Probe) loop
         if not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Entry_Body_Begin_Keyword,
               Current (Probe), "entry body begin keyword");
            declare
               Body_Start : Cursor := Probe;
            begin
               Advance (Body_Start);
               if At_End (Body_Start)
                 or else Current_Lower (Body_Start) = "end"
                 or else Current_Lower (Body_Start) = "or"
                 or else Current_Lower (Body_Start) = "else"
                 or else Current_Lower (Body_Start) = "then"
                 or else To_String (Current (Body_Start).Text) = ";"
               then
                  Add_Production
                    (Result,
                     Production_Entry_Body_Missing_Statement_Recovery_Boundary,
                     Current (Body_Start),
                     "entry body missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Body_Start),
                     "expected statement sequence in entry body");
               else
                  Add_Production
                    (Result, Production_Entry_Body_Statement_Sequence,
                     Current (Body_Start), "entry body statement sequence");
                  Add_Production
                    (Result, Production_Statement_Sequence,
                     Current (Body_Start), "entry body statement sequence");
               end if;
            end;
         elsif Current_Lower (Probe) = "end" then
            Add_Production
              (Result, Production_Entry_Body_End_Keyword,
               Current (Probe), "entry body end keyword");
            Advance (Probe);
            if not At_End (Probe)
              and then (Current (Probe).Kind = Token_Identifier
                        or else Current (Probe).Kind = Token_Keyword)
            then
               Add_Production
                 (Result, Production_Entry_Body_End_Name,
                  Current (Probe), "entry body end name");
               Advance (Probe);
            end if;
            if not At_End (Probe)
              and then To_String (Current (Probe).Text) = ";"
            then
               Add_Production
                 (Result, Production_Entry_Body_End_Terminator,
                  Current (Probe), "entry body end terminator");
            else
               Add_Production
                 (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position),
                  "entry body missing end terminator recovery boundary");
            end if;
            return;
         elsif Current_Lower (Probe) = "private"
           or else Current_Lower (Probe) = "or"
           or else Current_Lower (Probe) = "else"
         then
            if Found_Begin then
               Add_Production
                 (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Probe),
                  "entry body missing end terminator recovery boundary");
               return;
            end if;
         end if;

         Advance (Probe);
      end loop;

      if Found_Begin then
         Add_Production
           (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
            Current (Position),
            "entry body missing end terminator recovery boundary");
      end if;
   end Add_Entry_Body_Part_Productions;

end Editor.Ada_Token_Cursor.Entry_Parsing;
