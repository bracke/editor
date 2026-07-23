with Ada.Strings.Fixed;

with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;

   procedure Set_Pending_Body
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id)
   is
   begin
      Executable.Pending_Body_Owner := Owner;
   end Set_Pending_Body;

   procedure Clear_Pending_Body
     (Executable : in out Executable_Context)
   is
   begin
      Executable.Pending_Body_Owner := No_Symbol;
   end Clear_Pending_Body;

   procedure Clear_Pending_Body_For_Owner
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id)
   is
   begin
      if Executable.Pending_Body_Owner = Owner then
         Clear_Pending_Body (Executable);
      end if;
   end Clear_Pending_Body_For_Owner;

   procedure Set_Pending_Enumeration
     (Executable : in out Executable_Context;
      Owner      : Symbol_Id)
   is
   begin
      Executable.Pending_Enumeration := True;
      Executable.Pending_Enumeration_Owner := Owner;
   end Set_Pending_Enumeration;

   procedure Clear_Pending_Enumeration
     (Executable : in out Executable_Context)
   is
   begin
      Executable.Pending_Enumeration := False;
      Executable.Pending_Enumeration_Owner := No_Symbol;
   end Clear_Pending_Enumeration;

   function Handle_Executable_Continuation
     (Analysis                            : in out Analysis_Result;
      Raw_Line                            : String;
      Lower_Line                          : String;
      Line_Number                         : Positive;
      Depth                               : Natural;
      Parent                              : Symbol_Id;
      Starts_With_Declaration_Or_Metadata : Boolean;
      Targets                             : in out Declaration_Target_Context;
      Executable                          : in out Executable_Context;
      Scope                               : in out Scope_Context) return Boolean
   is
   begin
      if Executable.Pending_Body_Owner /= No_Symbol then
         declare
            Owner         : constant Symbol_Id := Executable.Pending_Body_Owner;
            Return_Target : constant String :=
              Return_Target_From_Line_Start (Raw_Line);
         begin
            if Return_Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Return_Target);
               if Targets.Pending_Return_Target_Owner = Owner then
                  Targets.Pending_Return_Target_Owner := No_Symbol;
               end if;
            end if;

            if Ada.Strings.Fixed.Index (Lower_Line, "return") /= 0
              and then Has_Token (Lower_Line, "access")
              and then not Has_Code_Char (Lower_Line, ';')
            then
               Targets.Pending_Return_Access_Target_Owner := Owner;
               return True;
            elsif Has_Token (Lower_Line, "is")
              and then not Has_Code_Char (Lower_Line, ';')
            then
               Parse_Line_Scope_Phase.Enter_Scope (Scope, Owner);
               Clear_Pending_Body (Executable);
               return True;
            elsif Has_Code_Char (Lower_Line, ';') then
               Clear_Pending_Body (Executable);
               return True;
            elsif Return_Target'Length /= 0 then
               return True;
            elsif Starts_With_Declaration_Or_Metadata then
               Clear_Pending_Body (Executable);
            else
               return True;
            end if;
         end;
      end if;

      if Executable.Pending_Enumeration then
         Declaration_Collectors.Add_Enumeration_Literals_Continuation
           (Analysis, Raw_Line, Line_Number, Depth + 1,
            (if Executable.Pending_Enumeration_Owner /= No_Symbol then
                Executable.Pending_Enumeration_Owner
             else
                Parent));
         if Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            Clear_Pending_Enumeration (Executable);
         end if;
         return True;
      end if;

      return False;
   end Handle_Executable_Continuation;

end Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase;
