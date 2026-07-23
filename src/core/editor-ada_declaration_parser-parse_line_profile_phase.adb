with Ada.Strings.Fixed;

with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;

   procedure Set_Pending_Profile
     (Profile : in out Profile_Context;
      Owner   : Symbol_Id)
   is
   begin
      Profile.Pending_Profile := True;
      Profile.Pending_Profile_Owner := Owner;
   end Set_Pending_Profile;

   procedure Clear_Pending_Profile (Profile : in out Profile_Context) is
   begin
      Profile.Pending_Profile := False;
      Profile.Pending_Profile_Owner := No_Symbol;
   end Clear_Pending_Profile;

   procedure Clear_Pending_Profile_For_Owner
     (Profile : in out Profile_Context;
      Owner   : Symbol_Id)
   is
   begin
      if Profile.Pending_Profile_Owner = Owner then
         Clear_Pending_Profile (Profile);
      end if;
   end Clear_Pending_Profile_For_Owner;

   procedure Clear_Pending_Access_Targets
     (Profile : in out Profile_Context)
   is
   begin
      Profile.Pending_Profile_Access_Target_Owners := (others => No_Symbol);
      Profile.Pending_Profile_Access_Target_Count := 0;
   end Clear_Pending_Access_Targets;

   procedure Handle_Pending_Profile_Continuation
     (Analysis       : in out Analysis_Result;
      Raw_Line       : String;
      Lower_Line     : String;
      Line_Number    : Positive;
      Depth          : Natural;
      Profile        : in out Profile_Context;
      Targets        : in out Declaration_Target_Context;
      Binding        : in out Executable_Binding_Context;
      Scope          : in out Scope_Context)
   is
      Closed_Profile : Boolean := False;
      Owner          : constant Symbol_Id := Profile.Pending_Profile_Owner;
   begin
      if Profile.Pending_Profile_Access_Target_Count > 0 then
         declare
            Target : constant String := Access_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               for I in 1 .. Profile.Pending_Profile_Access_Target_Count loop
                  Set_Symbol_Target
                    (Analysis,
                     Profile.Pending_Profile_Access_Target_Owners (I),
                     Target);
               end loop;
               Clear_Pending_Access_Targets (Profile);
            elsif Has_Code_Char (Lower_Line, ';') then
               Clear_Pending_Access_Targets (Profile);
            end if;
         end;
      end if;

      Profile_Parameter_Collectors.Add_Profile_Parameter_Names_Continuation
        (Analysis, Raw_Line, Line_Number, Depth + 1, Owner,
         Profile.Pending_Profile_Access_Target_Owners,
         Profile.Pending_Profile_Access_Target_Count,
         Closed_Profile);

      if Owner /= No_Symbol then
         declare
            Continuation_Profile : constant String :=
              Profile_Continuation_From_Line (Raw_Line);
            Return_Target : constant String :=
              Return_Target_From_Line_Start (Raw_Line);
            Formal_Default_Target : constant String :=
              Generic_Formal_Subprogram_Default_After_Is (Raw_Line);
         begin
            if Continuation_Profile'Length /= 0 then
               Set_Symbol_Profile (Analysis, Owner, Continuation_Profile);
            end if;

            if Return_Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Return_Target);
               if Targets.Pending_Return_Target_Owner = Owner then
                  Targets.Pending_Return_Target_Owner := No_Symbol;
               end if;
            end if;

            if Symbol (Analysis, Owner).Kind = Symbol_Generic_Formal_Subprogram then
               if Formal_Default_Target'Length /= 0 then
                  Set_Symbol_Target (Analysis, Owner, Formal_Default_Target);
               elsif Has_Token (Lower_Line, "is")
                 and then not Has_Code_Char (Lower_Line, ';')
               then
                  Targets.Pending_Generic_Formal_Subprogram_Target_Owner :=
                    Owner;
               end if;
            end if;
         end;
      end if;

      if Closed_Profile
        or else Has_Token (Lower_Line, "is")
        or else (Has_Code_Char (Lower_Line, ';')
                 and then Ada.Strings.Fixed.Index (Lower_Line, ":") = 0
                 and then Ada.Strings.Fixed.Index (Lower_Line, "(") = 0
                 and then Ada.Strings.Fixed.Index (Lower_Line, ")") = 0)
      then
         if Owner /= No_Symbol
           and then Closed_Profile
           and then not Has_Token (Lower_Line, "is")
           and then not Has_Code_Char (Lower_Line, ';')
           and then not Symbol (Analysis, Owner).Flags.Is_Rename
           and then not Symbol (Analysis, Owner).Flags.Is_Instantiation
         then
            Parse_Line_Executable_Phase.Set_Pending_Body (Binding, Owner);
         end if;
         Clear_Pending_Profile (Profile);
         if Profile.Pending_Profile_Access_Target_Count > 0 then
            Clear_Pending_Access_Targets (Profile);
         end if;
      end if;

      if Owner /= No_Symbol
        and then Has_Token (Lower_Line, "is")
        and then not Has_Code_Char (Lower_Line, ';')
        and then Symbol (Analysis, Owner).Kind /= Symbol_Generic_Formal_Subprogram
      then
         Parse_Line_Scope_Phase.Enter_Scope (Scope, Owner);
      end if;
   end Handle_Pending_Profile_Continuation;

end Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase;
