with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Semantic_Core;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser is

   function Parse
     (Text         : String;
      Buffer_Label : String := "") return Editor.Ada_Language_Model.Analysis_Result
   is
      use Editor.Ada_Language_Model;
      Analysis : Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Semantic_Core.Parse
          (Text         => Text,
           Buffer_Label => Buffer_Label);

      procedure Ignore_Reconciled_Record_Metadata
        (Flags : in out Declaration_Flags;
         Line  : String)
      is
         pragma Unreferenced (Line);
      begin
         Flags := Flags;
      end Ignore_Reconciled_Record_Metadata;

      procedure Reconcile_Compact_Record_Tails is
         Line_Start  : Positive := Text'First;
         Line_Number : Positive := 1;

         procedure Process_Line (First : Positive; Last : Natural) is
         begin
            if Last < First then
               return;
            end if;

            declare
               Raw_Line   : String (1 .. Last - First + 1);
            begin
               Raw_Line := Text (First .. Last);

               declare
                  Lower_Line : constant String :=
                    Editor.Text_Helpers.Lower
                      (Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line));
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
                         (Lower_Line,
                          Editor.Text_Helpers.Lower (To_String (Info.Name))) /= 0
                     then
                        declare
                           Record_Pos : constant Natural :=
                             Ada.Strings.Fixed.Index (Lower_Line, " record");
                           End_Pos : constant Natural :=
                             Ada.Strings.Fixed.Index (Lower_Line, "end record");
                           Tail_Line : String := Raw_Line;
                        begin
                           if Record_Pos /= 0 then
                              for J in Tail_Line'First ..
                                Natural'Min (Tail_Line'Last, Record_Pos + 6)
                              loop
                                 Tail_Line (J) := ' ';
                              end loop;

                              if End_Pos /= 0 then
                                 for J in End_Pos .. Tail_Line'Last loop
                                    Tail_Line (J) := ' ';
                                 end loop;
                              end if;

                              Editor.Ada_Declaration_Parser.Declaration_Collectors.
                                Add_Record_Component_Names
                                  (Analysis, Tail_Line, Line_Number,
                                   Natural'Min (Info.Depth + 1, 128),
                                   Info.Id,
                                   Ignore_Reconciled_Record_Metadata'Access);
                           end if;
                        end;
                     end if;
                  end;
               end loop;
               end;
            end;
         end Process_Line;
      begin
         if Text'Length = 0 then
            return;
         end if;

         for I in Text'Range loop
            if Text (I) = Ada.Characters.Latin_1.LF then
               declare
                  Line_End : Natural := I - 1;
               begin
                  if Line_End >= Line_Start
                    and then Text (Line_End) = Ada.Characters.Latin_1.CR
                  then
                     Line_End := Line_End - 1;
                  end if;
                  Process_Line (Line_Start, Line_End);
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
               Process_Line (Line_Start, Line_End);
            end;
         end if;
      end Reconcile_Compact_Record_Tails;
   begin
      Reconcile_Compact_Record_Tails;
      return Analysis;
   end Parse;

end Editor.Ada_Declaration_Parser;
