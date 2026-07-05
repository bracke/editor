with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Same_Line_Emitters is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Metadata_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;

   procedure Add_Same_Line_Subtype_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;

      procedure Add_Segment
        (First : Natural;
         Last  : Natural)
      is
      begin
         if First > Last then
            return;
         end if;

         declare
            Segment       : constant String := Trim (Raw_Line (First .. Last));
            Segment_Lower : constant String := Lower (Segment);
         begin
            if not Starts_With_Word (Segment_Lower, "subtype") then
               return;
            end if;

            declare
               Segment_Name : constant String :=
                 Read_Name (Segment, Segment'First + 7, True);
               Name_Pos     : constant Natural :=
                 Ada.Strings.Fixed.Index (Raw_Line (First .. Last), Segment_Name);
               Col          : constant Positive :=
                 (if Name_Pos = 0
                  then First_Non_Blank_Column (Raw_Line)
                  else Positive (Name_Pos));
               Segment_Flags : constant Declaration_Flags :=
                 (Is_Private => Parent_Is_Private, others => False);
            begin
               if Segment_Name'Length /= 0 then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Segment_Name, Symbol_Subtype,
                        (Line_Number, Col, Line_Number,
                         Positive'Max (Col, Col + Segment_Name'Length - 1)),
                        Col, Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth,
                        Flags => Segment_Flags,
                        Target_Name => Subtype_Target_After_Is (Segment));
                  begin
                     null;
                  end;
               end if;
            end;
         end;
      end Add_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = ';' then
            Add_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Same_Line_Subtype_Groups;

end Editor.Ada_Declaration_Parser.Same_Line_Emitters;
