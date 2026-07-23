with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;

use Editor.Ada_Language_Model;
use Editor.Ada_Declaration_Parser.Source_Awareness;
use Editor.Ada_Declaration_Parser.Metadata_Helpers;
separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Analysis_Result
   is
      pragma Unreferenced (Buffer_Label);
      Analysis : Analysis_Result;
      Line_Start : Positive := Text'First;
      Line_Number : Positive := 1;
      Context : Parse_Line_Context;
      Syntax_Tree_Value : Editor.Ada_Syntax_Tree.Tree_Type;

      procedure Reconcile_Compact_Record_Tails is
         Scan_Line_Start : Positive := Text'First;
         Scan_Line_Number : Positive := 1;

         procedure Ignore_Reconciled_Record_Metadata
           (Flags : in out Declaration_Flags;
            Line  : String)
         is
            pragma Unreferenced (Line);
         begin
            Flags := Flags;
         end Ignore_Reconciled_Record_Metadata;

         procedure Process_Line
           (First : Positive;
            Last  : Natural;
            Line  : Positive)
         is
         begin
            if Last < First then
               return;
            end if;

            declare
               Raw_Line   : constant String := "" & Text (First .. Last);
               Code_Line  : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
               Lower_Line : constant String := Editor.Text_Helpers.Lower (Code_Line);
            begin
               if Ada.Strings.Fixed.Index (Lower_Line, "record") = 0
                 or else Ada.Strings.Fixed.Index (Lower_Line, "type") = 0
               then
                  return;
               end if;

               for I in 1 .. Symbol_Count (Analysis) loop
                  declare
                     Info : constant Symbol_Info := Symbol_At (Analysis, I);
                  begin
                     if Info.Kind = Symbol_Record_Type
                       and then Ada.Strings.Fixed.Index
                         (Lower_Line, Editor.Text_Helpers.Lower
                            (To_String (Info.Name))) /= 0
                     then
                        Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase.
                          Parse_Compact_Record_Tail
                            (Analysis, Raw_Line, Line,
                             Natural'Min (Info.Depth, Max_Scope_Nesting),
                             Info.Id,
                             Ignore_Reconciled_Record_Metadata'Access);
                     end if;
                  end;
               end loop;
            end;
         end Process_Line;
      begin
         for I in Text'Range loop
            if Text (I) = Ada.Characters.Latin_1.LF then
               declare
                  Scan_Line_End : Natural := I - 1;
               begin
                  if Scan_Line_End >= Scan_Line_Start
                    and then Text (Scan_Line_End) = Ada.Characters.Latin_1.CR
                  then
                     Scan_Line_End := Scan_Line_End - 1;
                  end if;
                  Process_Line (Scan_Line_Start, Scan_Line_End, Scan_Line_Number);
               end;
               if I < Text'Last then
                  Scan_Line_Start := I + 1;
               end if;
               Scan_Line_Number := Scan_Line_Number + 1;
            end if;
         end loop;

         if Scan_Line_Start <= Text'Last then
            declare
               Scan_Line_End : Natural := Text'Last;
            begin
               if Text (Scan_Line_End) = Ada.Characters.Latin_1.CR then
                  Scan_Line_End := Scan_Line_End - 1;
               end if;
               Process_Line (Scan_Line_Start, Scan_Line_End, Scan_Line_Number);
            end;
         end if;
      end Reconcile_Compact_Record_Tails;
   begin
      Clear (Analysis);
      begin
         Syntax_Tree_Value := Editor.Ada_Syntax_Tree.Parse (Text);
         Set_Syntax_Tree (Analysis, Syntax_Tree_Value);
      exception
         when others =>
            Editor.Ada_Syntax_Tree.Clear (Syntax_Tree_Value);
      end;

      if Text'Length = 0 then
         return Analysis;
      end if;

      for I in Text'Range loop
         if Text (I) = Ada.Characters.Latin_1.LF then
            declare
               Line_End : Natural := I - 1;
            begin
               if Line_End >= Line_Start and then Text (Line_End) = Ada.Characters.Latin_1.CR then
                  Line_End := Line_End - 1;
               end if;
               if Line_End >= Line_Start then
                  Parse_Line (Analysis, "" & Text (Line_Start .. Line_End), Line_Number, Context);
               else
                  Parse_Line (Analysis, "", Line_Number, Context);
               end if;
            end;
            if I < Text'Last then
               Line_Start := I + 1;
            end if;
            Line_Number := Line_Number + 1;
         end if;
      end loop;

      if Line_Start <= Text'Last then
         declare
            Line_End : Natural := Text'Last;
         begin
            if Text (Line_End) = Ada.Characters.Latin_1.CR then
               Line_End := Line_End - 1;
            end if;
            if Line_End >= Line_Start then
               Parse_Line (Analysis, "" & Text (Line_Start .. Line_End), Line_Number, Context);
            end if;
         end;
      end if;

      Reconcile_Compact_Record_Tails;
      if Editor.Ada_Syntax_Tree.Has_Nodes (Syntax_Tree_Value) then
         begin
            Project_Syntax_Tree_Into_Model (Analysis, Syntax_Tree_Value, Text);
         exception
            when others =>
               null;
         end;
      end if;
      Reconcile_Compact_Record_Tails;
      Add_Executable_Bindings_From_Text (Analysis, Text);
      Add_Legality_Diagnostics (Analysis);
      return Analysis;
   exception
      when others =>
         begin
            Reconcile_Compact_Record_Tails;
         exception
            when others =>
               null;
         end;
         return Analysis;
   end Parse;
