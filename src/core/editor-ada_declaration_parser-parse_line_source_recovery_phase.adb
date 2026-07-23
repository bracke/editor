with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   procedure Set_Pending_Separate_Target
     (Recovery : in out Source_Recovery_Context;
      Text     : String)
   is
   begin
      Recovery.Pending_Separate_Target_Len :=
        Natural'Min (Text'Length, Recovery.Pending_Separate_Target'Length);
      if Recovery.Pending_Separate_Target_Len > 0 then
         Recovery.Pending_Separate_Target
           (Recovery.Pending_Separate_Target'First ..
              Recovery.Pending_Separate_Target'First
              + Recovery.Pending_Separate_Target_Len - 1) :=
           Text (Text'First .. Text'First
                 + Recovery.Pending_Separate_Target_Len - 1);
      end if;
   end Set_Pending_Separate_Target;

   function Has_Pending_Separate_Target
     (Recovery : Source_Recovery_Context) return Boolean
   is
   begin
      return Recovery.Pending_Separate_Target_Len > 0;
   end Has_Pending_Separate_Target;

   function Consume_Pending_Separate_Target
     (Recovery : in out Source_Recovery_Context) return String
   is
      Length : constant Natural := Recovery.Pending_Separate_Target_Len;
   begin
      Recovery.Pending_Separate_Target_Len := 0;
      if Length = 0 then
         return "";
      end if;

      return Recovery.Pending_Separate_Target
        (Recovery.Pending_Separate_Target'First ..
           Recovery.Pending_Separate_Target'First + Length - 1);
   end Consume_Pending_Separate_Target;

   procedure Set_Pending_Aspect_Owner
     (Recovery : in out Source_Recovery_Context;
      Owner    : Symbol_Id)
   is
   begin
      Recovery.Pending_Aspect_Owner := Owner;
   end Set_Pending_Aspect_Owner;

   function Handle_Pending_Aspect_Line
     (Analysis    : in out Analysis_Result;
      Recovery    : in out Source_Recovery_Context;
      Raw_Line    : String;
      Lower_Line  : String;
      Line_Number : Positive) return Boolean
   is
      function Is_Bare_Aspect_Line return Boolean is
         Code : constant String :=
           Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line));
         Segment : constant String :=
           (if Code'Length > 0 and then Code (Code'Last) = ';'
            then Trim (Code (Code'First .. Code'Last - 1))
            else Code);
      begin
         if Segment = ""
           or else Ada.Strings.Fixed.Index (Segment, "=>") /= 0
           or else Ada.Strings.Fixed.Index (Segment, ":") /= 0
           or else Ada.Strings.Fixed.Index (Segment, "(") /= 0
           or else Ada.Strings.Fixed.Index (Segment, ")") /= 0
           or else Ada.Strings.Fixed.Index (Segment, " ") /= 0
           or else Ada.Strings.Fixed.Index
             (Segment, Ada.Characters.Latin_1.HT & "") /= 0
         then
            return False;
         end if;

         for C of Segment loop
            if not (Is_Word_Char (C) or else C = Character'Val (39)) then
               return False;
            end if;
         end loop;

         return Representation_Metadata.Representation_Kind_For
           ("Target" & Character'Val (39) & Segment, "True") /=
           Representation_Record_Clause;
      exception
         when Constraint_Error =>
            return False;
      end Is_Bare_Aspect_Line;

      procedure Add_Pending_Aspect_Line is
         Code : constant String :=
           Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line));
         Segment : constant String :=
           (if Starts_With_Word (Lower (Code), "with")
            then Trim (Code (Code'First + 4 .. Code'Last))
            else Code);
         Clean : constant String :=
           (if Segment'Length > 0
              and then (Segment (Segment'Last) = ','
                        or else Segment (Segment'Last) = ';')
            then Trim (Segment (Segment'First .. Segment'Last - 1))
            else Segment);
         Arrow : constant Natural := Ada.Strings.Fixed.Index (Clean, "=>");
         Aspect_Name : constant String :=
           (if Arrow /= 0 then Trim (Clean (Clean'First .. Arrow - 1))
            else Clean);
         Raw_Value : constant String :=
           (if Arrow /= 0 and then Arrow + 2 <= Clean'Last
            then Trim (Clean (Arrow + 2 .. Clean'Last))
            else "");
         Value_Comma : constant Natural :=
           Ada.Strings.Fixed.Index (Raw_Value, ",");
         Value : constant String :=
           (if Raw_Value = "" then "True"
            elsif Value_Comma /= 0 then
              Trim (Raw_Value (Raw_Value'First .. Value_Comma - 1))
            elsif Ends_With (Lower (Raw_Value), " is")
              and then Raw_Value'Length > 3
            then Trim (Raw_Value (Raw_Value'First .. Raw_Value'Last - 3))
            else Raw_Value);
         Owner_Info : constant Symbol_Info :=
           Symbol (Analysis, Recovery.Pending_Aspect_Owner);
         Target_Text : constant String := To_String (Owner_Info.Name);
         Kind : constant Representation_Clause_Kind :=
           Representation_Metadata.Representation_Kind_For
             (Target_Text & Character'Val (39) & Aspect_Name, Value);
      begin
         if Aspect_Name = "" or else Kind = Representation_Record_Clause then
            return;
         end if;

         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Recovery.Pending_Aspect_Owner,
            Target_Name => Target_Text,
            Kind => Kind,
            Attribute_Name => Aspect_Name,
            Item_Text => Value,
            Source_Form => Representation_Source_Aspect,
            Source_Span =>
              (Line_Number,
               Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
               Line_Number,
               Positive'Max
                 (Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
                  Metadata_Helpers.First_Non_Blank_Column (Raw_Line)
                  + Clean'Length - 1)));

         if Value_Comma /= 0 and then Value_Comma + 1 <= Raw_Value'Last then
            declare
               Rest : constant String :=
                 Trim (Raw_Value (Value_Comma + 1 .. Raw_Value'Last));
               Rest_Arrow : constant Natural :=
                 Ada.Strings.Fixed.Index (Rest, "=>");
               Rest_Name : constant String :=
                 (if Rest_Arrow /= 0
                  then Trim (Rest (Rest'First .. Rest_Arrow - 1))
                  else Rest);
               Rest_Value_Raw : constant String :=
                 (if Rest_Arrow /= 0 and then Rest_Arrow + 2 <= Rest'Last
                  then Trim (Rest (Rest_Arrow + 2 .. Rest'Last))
                  else "");
               Rest_Comma : constant Natural :=
                 Ada.Strings.Fixed.Index (Rest_Value_Raw, ",");
               Rest_Value : constant String :=
                 (if Rest_Value_Raw = "" then "True"
                  elsif Rest_Comma /= 0 then
                    Trim
                      (Rest_Value_Raw
                         (Rest_Value_Raw'First .. Rest_Comma - 1))
                  elsif Ends_With (Lower (Rest_Value_Raw), " is")
                    and then Rest_Value_Raw'Length > 3
                  then
                    Trim
                      (Rest_Value_Raw
                         (Rest_Value_Raw'First ..
                          Rest_Value_Raw'Last - 3))
                  else Rest_Value_Raw);
               Rest_Kind : constant Representation_Clause_Kind :=
                 Representation_Metadata.Representation_Kind_For
                   (Target_Text & Character'Val (39) & Rest_Name,
                    Rest_Value);
            begin
               if Rest_Name /= ""
                 and then Rest_Kind /= Representation_Record_Clause
               then
                  Add_Representation_Clause
                    (Analysis,
                     Target_Symbol => Recovery.Pending_Aspect_Owner,
                     Target_Name => Target_Text,
                     Kind => Rest_Kind,
                     Attribute_Name => Rest_Name,
                     Item_Text => Rest_Value,
                     Source_Form => Representation_Source_Aspect,
                     Source_Span =>
                       (Line_Number,
                        Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
                        Line_Number,
                        Positive'Max
                          (Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
                           Metadata_Helpers.First_Non_Blank_Column (Raw_Line)
                           + Rest'Length - 1)));
               end if;
            end;
         end if;
      exception
         when Constraint_Error =>
            null;
      end Add_Pending_Aspect_Line;
   begin
      if Recovery.Pending_Aspect_Owner = No_Symbol then
         return False;
      end if;

      if Starts_With_Word (Lower_Line, "with")
        and then not Starts_With_Word (Lower_Line, "with package")
        and then not Starts_With_Word (Lower_Line, "with procedure")
        and then not Starts_With_Word (Lower_Line, "with function")
        and then not Starts_With_Word (Lower_Line, "with type")
      then
         Mark_Symbol_Aspect_Specification
           (Analysis, Recovery.Pending_Aspect_Owner);
         if Has_Code_Char (Lower_Line, ';') then
            Recovery.Pending_Aspect_Owner := No_Symbol;
         end if;
         return True;
      elsif Ada.Strings.Fixed.Index (Lower_Line, "=>") /= 0
        and then not Line_Dispatch.Starts_With_Declaration_Or_Metadata
          (Lower_Line)
      then
         Add_Pending_Aspect_Line;
         Mark_Symbol_Aspect_Specification
           (Analysis, Recovery.Pending_Aspect_Owner);
         if Has_Code_Char (Lower_Line, ';') then
            Recovery.Pending_Aspect_Owner := No_Symbol;
         end if;
         return True;
      elsif Is_Bare_Aspect_Line
        and then not Line_Dispatch.Starts_With_Declaration_Or_Metadata
          (Lower_Line)
        and then Has_Code_Char (Lower_Line, ';')
      then
         Add_Pending_Aspect_Line;
         Mark_Symbol_Aspect_Specification
           (Analysis, Recovery.Pending_Aspect_Owner);
         Recovery.Pending_Aspect_Owner := No_Symbol;
         return True;
      else
         Recovery.Pending_Aspect_Owner := No_Symbol;
         return False;
      end if;
   end Handle_Pending_Aspect_Line;

   procedure Add_Trailing_Bare_Aspect
     (Analysis    : in out Analysis_Result;
      Owner       : Symbol_Id;
      Raw_Line    : String;
      Line_Number : Positive)
   is
      Code : constant String :=
        Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line));
      Lower_Code : constant String := Lower (Code);
      With_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Lower_Code, " with ");
      Stop_Pos : Natural := 0;
      Stop_Is  : Boolean := False;
      Last_Comma : Natural := 0;
      Aspect_Start : Natural := 0;
   begin
      if Owner = No_Symbol or else With_Pos = 0 then
         return;
      end if;

      Stop_Pos := Ada.Strings.Fixed.Index (Lower_Code, " is");
      Stop_Is := Stop_Pos /= 0;
      if not Stop_Is then
         Stop_Pos := Ada.Strings.Fixed.Index (Lower_Code, ";");
      end if;
      if Stop_Pos = 0 or else Stop_Pos <= With_Pos + 6 then
         return;
      end if;

      for I in With_Pos + 6 .. Stop_Pos - 1 loop
         if Code (I) = ',' then
            Last_Comma := I;
         end if;
      end loop;

      if Last_Comma /= 0 then
         Aspect_Start := Last_Comma + 1;
      elsif Stop_Is then
         Aspect_Start := With_Pos + 6;
      else
         return;
      end if;

      declare
         Aspect_Name : constant String :=
           Trim (Code (Aspect_Start .. Stop_Pos - 1));
         Owner_Info : constant Symbol_Info := Symbol (Analysis, Owner);
         Target_Text : constant String := To_String (Owner_Info.Name);
         Kind : constant Representation_Clause_Kind :=
           Representation_Metadata.Representation_Kind_For
             (Target_Text & Character'Val (39) & Aspect_Name, "True");
      begin
         if Aspect_Name = ""
           or else Ada.Strings.Fixed.Index (Aspect_Name, "=>") /= 0
           or else Kind = Representation_Record_Clause
         then
            return;
         end if;

         Add_Representation_Clause
           (Analysis,
            Target_Symbol => Owner,
            Target_Name => Target_Text,
            Kind => Kind,
            Attribute_Name => Aspect_Name,
            Item_Text => "True",
            Source_Form => Representation_Source_Aspect,
            Source_Span =>
              (Line_Number,
               Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
               Line_Number,
               Positive'Max
                 (Metadata_Helpers.First_Non_Blank_Column (Raw_Line),
                  Metadata_Helpers.First_Non_Blank_Column (Raw_Line)
                  + Aspect_Name'Length - 1)));
      end;
   exception
      when Constraint_Error =>
         null;
   end Add_Trailing_Bare_Aspect;

end Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase;
