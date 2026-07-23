with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;

with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Line_Metadata;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Same_Line_Declarations;
with Editor.Ada_Declaration_Parser.Same_Line_Emitters;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Language_Model;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Metadata_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;
   use Editor.Text_Helpers;

   procedure Begin_Generic (Targets : in out Declaration_Target_Context) is
   begin
      Targets.Pending_Generic := True;
   end Begin_Generic;

   procedure Consume_Generic_Unit
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Generic := False;
   end Consume_Generic_Unit;

   procedure Set_Pending_Type_Header
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Type_Header_Owner := Owner;
   end Set_Pending_Type_Header;

   procedure Set_Pending_Record_After_Is
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Record_After_Is_Owner := Owner;
   end Set_Pending_Record_After_Is;

   procedure Set_Pending_Concurrent_Header
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Concurrent_Header_Owner := Owner;
   end Set_Pending_Concurrent_Header;

   procedure Set_Pending_Array_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Array_Target_Owner := Owner;
   end Set_Pending_Array_Target;

   procedure Set_Pending_Access_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Access_Target_Owner := Owner;
      Targets.Pending_Access_Subprogram_Profile_Owner := Owner;
   end Set_Pending_Access_Target;

   procedure Set_Pending_Return_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Return_Target_Owner := Owner;
   end Set_Pending_Return_Target;

   procedure Set_Pending_Return_Access_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Return_Access_Target_Owner := Owner;
   end Set_Pending_Return_Access_Target;

   procedure Set_Pending_Subtype_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Subtype_Target_Owner := Owner;
   end Set_Pending_Subtype_Target;

   procedure Set_Pending_Derived_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Derived_Target_Owner := Owner;
   end Set_Pending_Derived_Target;

   procedure Set_Pending_Interface_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Interface_Target_Owner := Owner;
   end Set_Pending_Interface_Target;

   procedure Set_Pending_Declaration_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Declaration_Target_Owner := Owner;
   end Set_Pending_Declaration_Target;

   procedure Set_Pending_Generic_Formal_Package_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Generic_Formal_Package_Target_Owner := Owner;
   end Set_Pending_Generic_Formal_Package_Target;

   procedure Set_Pending_Generic_Formal_Subprogram_Target
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id) is
   begin
      Targets.Pending_Generic_Formal_Subprogram_Target_Owner := Owner;
   end Set_Pending_Generic_Formal_Subprogram_Target;

   procedure Start_Pending_Object_Array_Targets
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Object_Array_Target_Count := 0;
      Targets.Pending_Object_Array_Target_Owners := (others => No_Symbol);
   end Start_Pending_Object_Array_Targets;

   procedure Start_Pending_Object_Access_Targets
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Object_Access_Target_Count := 0;
      Targets.Pending_Object_Access_Target_Owners := (others => No_Symbol);
   end Start_Pending_Object_Access_Targets;

   procedure Start_Pending_Object_Access_Subprogram_Profiles
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Object_Access_Subprogram_Profile_Count := 0;
      Targets.Pending_Object_Access_Subprogram_Profile_Owners :=
        (others => No_Symbol);
   end Start_Pending_Object_Access_Subprogram_Profiles;

   procedure Start_Pending_Generic_Formal_Object_Targets
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Generic_Formal_Object_Target_Count := 0;
      Targets.Pending_Generic_Formal_Object_Target_Owners :=
        (others => No_Symbol);
   end Start_Pending_Generic_Formal_Object_Targets;

   procedure Set_Pending_Discriminants
     (Targets : in out Declaration_Target_Context;
      Owner   : Symbol_Id)
   is
   begin
      Targets.Pending_Discriminants := True;
      Targets.Pending_Discriminant_Owner := Owner;
   end Set_Pending_Discriminants;

   procedure Clear_Pending_Discriminants
     (Targets : in out Declaration_Target_Context)
   is
   begin
      Targets.Pending_Discriminants := False;
      Targets.Pending_Discriminant_Owner := No_Symbol;
   end Clear_Pending_Discriminants;

   function Object_Kind_For (Line : String) return Symbol_Kind is
   begin
      if Has_Object_Constant_Qualifier (Line) then
         return Symbol_Constant;
      else
         return Symbol_Object;
      end if;
   end Object_Kind_For;

   function Handle_Generic_Formal_Object_Line
     (Analysis    : in out Analysis_Result;
      Decl        : String;
      Decl_Lower  : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Targets     : in out Declaration_Target_Context) return Boolean
   is
      Formal_Start : Natural := Decl'First + 4;
   begin
      if not Has_Declaration_Colon (Decl_Lower) then
         return False;
      end if;

      while Formal_Start <= Decl'Last
        and then (Decl (Formal_Start) = ' '
                  or else Decl (Formal_Start) = Ada.Characters.Latin_1.HT)
      loop
         Formal_Start := Formal_Start + 1;
      end loop;

      if Formal_Start > Decl'Last then
         return True;
      end if;

      if not Has_Code_Char (Decl_Lower, ';') then
         Start_Pending_Generic_Formal_Object_Targets (Targets);
         Declaration_Collectors.Add_Object_Names_Collecting
           (Analysis, Decl (Formal_Start .. Decl'Last), Line_Number,
            Depth, Parent, Symbol_Generic_Formal_Object,
            Type_Target =>
              Target_Helpers.Object_Target_After_Colon
                (Decl (Formal_Start .. Decl'Last)),
            Column_Base => Formal_Start - Decl'First,
            Flags =>
              Parse_Line_Metadata_Phase.Generic_Formal_Object_Flags (Decl),
            Collected => Targets.Pending_Generic_Formal_Object_Target_Owners,
            Collected_Count =>
              Targets.Pending_Generic_Formal_Object_Target_Count);
      else
         declare
            Owners  : Collected_Symbol_List := (others => No_Symbol);
            Count   : Natural := 0;
            Segment : constant String := Decl (Formal_Start .. Decl'Last);
            Profile : constant String :=
              Target_Helpers.Access_Subprogram_Profile (Segment);
         begin
            Declaration_Collectors.Add_Object_Names_Collecting
              (Analysis, Segment, Line_Number,
               Depth, Parent, Symbol_Generic_Formal_Object,
               Type_Target => Target_Helpers.Object_Target_After_Colon (Segment),
               Column_Base => Formal_Start - Decl'First,
               Flags =>
                 Parse_Line_Metadata_Phase.Generic_Formal_Object_Flags (Decl),
               Collected => Owners, Collected_Count => Count);
            if Profile'Length /= 0 then
               for I in 1 .. Count loop
                  Set_Symbol_Profile (Analysis, Owners (I), Profile);
               end loop;
            end if;
         end;
      end if;

      return True;
   end Handle_Generic_Formal_Object_Line;

   function Handle_Object_Declaration_Line
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Decl        : String;
      Decl_Lower  : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Flags       : Declaration_Flags;
      Targets     : in out Declaration_Target_Context) return Boolean
   is
   begin
      if Targets.Pending_Generic
        and then Has_Declaration_Colon (Decl_Lower)
        and then Has_Code_Char (Decl_Lower, ';')
      then
         Declaration_Collectors.Add_Object_Declaration_Groups
           (Analysis, Decl, Line_Number, Depth, Parent,
            Symbol_Generic_Formal_Object,
            Flags =>
              Parse_Line_Metadata_Phase.Generic_Formal_Object_Flags (Decl));
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then Has_Token (Decl_Lower, "array")
        and then not Has_Code_Char (Decl_Lower, ';')
      then
         Start_Pending_Object_Array_Targets (Targets);
         Declaration_Collectors.Add_Object_Names_Collecting
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Object_Kind_For (Decl),
            Type_Target => Target_Helpers.Object_Target_After_Colon (Raw_Line),
            Flags => Flags,
            Collected => Targets.Pending_Object_Array_Target_Owners,
            Collected_Count => Targets.Pending_Object_Array_Target_Count);
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then Has_Token (Decl_Lower, "access")
        and then (Has_Token (Decl_Lower, "procedure")
                  or else Has_Token (Decl_Lower, "function"))
        and then not Has_Code_Char (Decl_Lower, ';')
      then
         Start_Pending_Object_Access_Subprogram_Profiles (Targets);
         Declaration_Collectors.Add_Object_Names_Collecting
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Object_Kind_For (Decl),
            Type_Target => Target_Helpers.Object_Target_After_Colon (Raw_Line),
            Flags => Flags,
            Collected =>
              Targets.Pending_Object_Access_Subprogram_Profile_Owners,
            Collected_Count =>
              Targets.Pending_Object_Access_Subprogram_Profile_Count);
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then Has_Token (Decl_Lower, "access")
        and then not Has_Token (Decl_Lower, "procedure")
        and then not Has_Token (Decl_Lower, "function")
        and then not Has_Code_Char (Decl_Lower, ';')
      then
         Start_Pending_Object_Access_Targets (Targets);
         Declaration_Collectors.Add_Object_Names_Collecting
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Object_Kind_For (Decl),
            Type_Target => Target_Helpers.Object_Target_After_Colon (Raw_Line),
            Flags => Flags,
            Collected => Targets.Pending_Object_Access_Target_Owners,
            Collected_Count => Targets.Pending_Object_Access_Target_Count);
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then not Has_Code_Char (Decl_Lower, ';')
      then
         Declaration_Collectors.Add_Object_Names
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Object_Kind_For (Decl),
            Type_Target => Target_Helpers.Object_Target_After_Colon (Raw_Line),
            Flags => Flags);
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then Has_Token (Decl_Lower, "access")
        and then (Has_Token (Decl_Lower, "procedure")
                  or else Has_Token (Decl_Lower, "function"))
        and then Has_Code_Char (Decl_Lower, ';')
      then
         Declaration_Collectors.Add_Object_Declaration_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Object_Kind_For (Decl), Flags => Flags);
         return True;
      elsif Has_Declaration_Colon (Decl_Lower)
        and then Has_Code_Char (Decl_Lower, ';')
      then
         if Ada.Strings.Fixed.Index (Decl_Lower, ": exception") /= 0 then
            Declaration_Collectors.Add_Object_Declaration_Groups
              (Analysis, Raw_Line, Line_Number, Depth, Parent,
               Symbol_Exception, Flags => Flags);
         else
            Declaration_Collectors.Add_Object_Declaration_Groups
              (Analysis, Raw_Line, Line_Number, Depth, Parent,
               Object_Kind_For (Decl), Flags => Flags);
         end if;
         return True;
      end if;

      return False;
   end Handle_Object_Declaration_Line;

   function Has_Header_Discriminant_Part (Decl_Lower : String) return Boolean is
      Open_Pos  : constant Natural := Ada.Strings.Fixed.Index (Decl_Lower, "(");
      Colon_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl_Lower, ":");
      Close_Pos : constant Natural := Ada.Strings.Fixed.Index (Decl_Lower, ")");
      Is_Pos    : constant Natural := Ada.Strings.Fixed.Index (Decl_Lower, " is");
   begin
      return Open_Pos /= 0
        and then (Is_Pos = 0 or else Open_Pos < Is_Pos)
        and then (Colon_Pos > Open_Pos
                  or else (Colon_Pos = 0
                           and then Close_Pos = 0
                           and then not Has_Token (Decl_Lower, "access")));
   end Has_Header_Discriminant_Part;

   function Recognize_Declaration_Line
     (Analysis       : in out Analysis_Result;
      Raw_Line       : String;
      Raw_Decl       : String;
      Decl           : String;
      Decl_Lower     : String;
      Line_Number    : Positive;
      Depth          : Natural;
      Parent         : Symbol_Id;
      Scope          : in out Scope_Context;
      Targets        : in out Declaration_Target_Context;
      State          : in out Phase_State) return Boolean
   is
      Flags renames State.Flags;
      Kind  renames State.Kind;

      procedure Set_Name (S : String) is
      begin
         Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Set_Name
           (State, S);
      end Set_Name;

      procedure Set_Target (S : String) is
      begin
         Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Set_Target
           (State, S);
      end Set_Target;

      procedure Set_Profile (S : String) is
      begin
         Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Set_Profile
           (State, S);
      end Set_Profile;

      function Current_Name return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Name_Text
           (State);
      end Current_Name;
   begin
      if Targets.Pending_Generic and then Starts_With_Word (Decl_Lower, "with") then
         if Starts_With (Decl_Lower, "with package ") then
            Kind := Symbol_Generic_Formal_Package;
            Set_Name (Read_Name (Decl, Decl'First + 13, True));
            if Has_Token (Decl_Lower, "new") then
               Flags.Is_Instantiation := True;
               Flags.Has_Generic_Actual_Part_Metadata :=
                 Line_Metadata.Has_Generic_Actual_Part_Metadata (Decl);
               Set_Target (Target_After (Decl, "new"));
            end if;
         elsif Starts_With (Decl_Lower, "with procedure ") then
            Kind := Symbol_Generic_Formal_Subprogram;
            Set_Name (Read_Name (Decl, Decl'First + 15, True));
            if State.Name_Len > 0 then
               Set_Profile (Profile_From (Decl, Current_Name));
            end if;
            Set_Target (Target_After (Decl, " is "));
         elsif Starts_With (Decl_Lower, "with function ") then
            Kind := Symbol_Generic_Formal_Subprogram;
            declare
               Code_F : constant String :=
                 Read_Function_Name (Decl, Decl'First + 14, True);
               Raw_F  : constant String :=
                 Read_Function_Name (Raw_Decl, Raw_Decl'First + 14, True);
            begin
               Set_Name
                 ((if Raw_F'Length > 0 and then Raw_F (Raw_F'First) = '"' then Raw_F
                   elsif Code_F'Length /= 0 then Code_F
                   else Raw_F));
            end;
            if State.Name_Len > 0 then
               Set_Profile (Profile_From (Raw_Decl, Current_Name));
            end if;
            declare
               Default_Target : constant String :=
                 Generic_Formal_Subprogram_Default_After_Is (Decl);
            begin
               if Default_Target = "<>" then
                  Set_Target (Default_Target);
               else
                  Set_Target (Function_Return_Target (Decl));
               end if;
            end;
         elsif Handle_Generic_Formal_Object_Line
           (Analysis, Decl, Decl_Lower, Line_Number, Depth, Parent, Targets)
         then
            return True;
         else
            null;
         end if;
      elsif Targets.Pending_Generic and then Starts_With_Word (Decl_Lower, "type") then
         Kind := Symbol_Generic_Formal_Type;
         Set_Name (Read_Name (Decl, Decl'First + 4, True));
         Parse_Line_Metadata_Phase.Mark_Type_Qualifier_Metadata (Flags, Decl);
         if Has_Token (Decl_Lower, "new")
           and then not Has_Token (Decl_Lower, "access")
         then
            Flags.Has_Derived_Metadata := True;
            Set_Target (Target_After (Decl, "new"));
         elsif Has_Token (Decl_Lower, "array") then
            Set_Target (Array_Element_Target (Decl));
         elsif Has_Token (Decl_Lower, "access") then
            Set_Target (Access_Object_Target (Decl));
            Set_Profile (Access_Subprogram_Profile (Decl));
         elsif Has_Token (Decl_Lower, "interface") then
            Set_Target (Interface_Parent_Target (Decl));
         end if;
         if Has_Header_Discriminant_Part (Decl_Lower)
           and then Ada.Strings.Fixed.Index (Decl_Lower, ")") /= 0
         then
            Targets.Pending_Discriminants := True;
         elsif Has_Header_Discriminant_Part (Decl_Lower)
           and then Ada.Strings.Fixed.Index (Decl_Lower, ")") = 0
           and then not Has_Token (Decl_Lower, "is")
         then
            Targets.Pending_Discriminants := True;
         end if;
      elsif Starts_With (Decl_Lower, "package body ") then
         Kind := Symbol_Package_Body;
         Flags.Is_Body := True;
         Set_Name (Read_Name (Decl, Decl'First + 13, True));
      elsif Starts_With_Word (Decl_Lower, "package") then
         Flags.Is_Instantiation := Has_Token (Decl_Lower, "new");
         if Flags.Is_Instantiation then
            Flags.Has_Generic_Actual_Part_Metadata :=
              Line_Metadata.Has_Generic_Actual_Part_Metadata (Decl);
         end if;
         Kind :=
           (if Flags.Is_Instantiation then Symbol_Instantiation else Symbol_Package);
         Set_Name (Read_Name (Decl, Decl'First + 7, True));
         if Flags.Is_Rename then
            Set_Target (Target_After (Decl, "renames"));
         elsif Flags.Is_Instantiation then
            Set_Target (Target_After (Decl, "new"));
         end if;
      elsif Starts_With_Word (Decl_Lower, "procedure") then
         Flags.Is_Instantiation := Has_Token (Decl_Lower, "new");
         if Flags.Is_Instantiation then
            Flags.Has_Generic_Actual_Part_Metadata :=
              Line_Metadata.Has_Generic_Actual_Part_Metadata (Decl);
         end if;
         Kind :=
           (if Flags.Is_Instantiation then Symbol_Instantiation else Symbol_Procedure);
         Set_Name (Read_Name (Decl, Decl'First + 9, True));
         if State.Name_Len > 0 then
            Set_Profile (Profile_From (Decl, Current_Name));
         end if;
         if Flags.Is_Rename then
            Set_Target (Target_After (Decl, "renames"));
         elsif Flags.Is_Instantiation then
            Set_Target (Target_After (Decl, "new"));
         end if;
      elsif Starts_With_Word (Decl_Lower, "function") then
         Flags.Is_Instantiation := Has_Token (Decl_Lower, "new");
         if Flags.Is_Instantiation then
            Flags.Has_Generic_Actual_Part_Metadata :=
              Line_Metadata.Has_Generic_Actual_Part_Metadata (Decl);
         end if;
         declare
            Code_F : constant String :=
              Read_Function_Name (Decl, Decl'First + 8, True);
            Raw_F  : constant String :=
              Read_Function_Name (Raw_Decl, Raw_Decl'First + 8, True);
            F      : constant String :=
              (if Raw_F'Length > 0 and then Raw_F (Raw_F'First) = '"' then Raw_F
               elsif Code_F'Length /= 0 then Code_F
               else Raw_F);
         begin
            Kind :=
              (if F'Length > 0 and then F (F'First) = '"' then
                  Symbol_Operator_Function
               else
                  Symbol_Function);
            if Flags.Is_Instantiation then
               Kind := Symbol_Instantiation;
            end if;
            Set_Name (F);
            if State.Name_Len > 0 then
               Set_Profile (Profile_From (Raw_Decl, Current_Name));
            end if;
            if Flags.Is_Rename then
               Set_Target (Target_After (Decl, "renames"));
            elsif Flags.Is_Instantiation then
               Set_Target (Target_After (Decl, "new"));
            elsif State.Target_Len = 0 then
               Set_Target (Function_Return_Target (Decl));
               if State.Target_Len = 0
                 and then Ada.Strings.Fixed.Index (Decl_Lower, " return ") /= 0
                 and then (Ada.Strings.Fixed.Index
                             (Decl_Lower, " access procedure") /= 0
                           or else Ada.Strings.Fixed.Index
                             (Decl_Lower, " access function") /= 0
                           or else Ada.Strings.Fixed.Index
                             (Decl_Lower, " access protected procedure") /= 0
                           or else Ada.Strings.Fixed.Index
                             (Decl_Lower, " access protected function") /= 0)
               then
                  Set_Profile (Access_Subprogram_Profile (Decl));
               end if;
            end if;
         end;
      elsif Starts_With_Word (Decl_Lower, "subtype") then
         Kind := Symbol_Subtype;
         Set_Name (Read_Name (Decl, Decl'First + 7, True));
         Set_Target (Subtype_Target_After_Is (Decl));
      elsif Starts_With_Word (Decl_Lower, "type") then
         if Has_Token (Decl_Lower, "record") then
            Kind := Symbol_Record_Type;
            Parse_Line_Scope_Phase.Set_In_Record
              (Scope, not Has_Code_Char (Decl_Lower, ';'));
         else
            Kind := Symbol_Type;
         end if;
         Set_Name (Read_Name (Decl, Decl'First + 4, True));
         Parse_Line_Metadata_Phase.Mark_Type_Qualifier_Metadata (Flags, Decl);
         if Has_Token (Decl_Lower, "new")
           and then not Has_Token (Decl_Lower, "access")
         then
            Flags.Has_Derived_Metadata := True;
            Set_Target (Target_After (Decl, "new"));
         elsif Has_Token (Decl_Lower, "array") then
            Set_Target (Array_Element_Target (Decl));
         elsif Has_Token (Decl_Lower, "access") then
            Set_Target (Access_Object_Target (Decl));
            Set_Profile (Access_Subprogram_Profile (Decl));
         elsif Has_Token (Decl_Lower, "interface") then
            Set_Target (Interface_Parent_Target (Decl));
         end if;
         if Ada.Strings.Fixed.Index (Decl_Lower, "(") = 0
           and then not Has_Token (Decl_Lower, "is")
           and then not Has_Code_Char (Decl_Lower, ';')
         then
            Targets.Pending_Discriminants := False;
         elsif Has_Header_Discriminant_Part (Decl_Lower)
           and then Ada.Strings.Fixed.Index (Decl_Lower, ")") /= 0
         then
            Targets.Pending_Discriminants := True;
         elsif Has_Header_Discriminant_Part (Decl_Lower)
           and then Ada.Strings.Fixed.Index (Decl_Lower, ")") = 0
           and then not Has_Token (Decl_Lower, "is")
         then
            Targets.Pending_Discriminants := True;
         end if;
      elsif Starts_With (Decl_Lower, "task body ") then
         Kind := Symbol_Task;
         Set_Name (Read_Name (Decl, Decl'First + 10, True));
      elsif Starts_With (Decl_Lower, "task type ") then
         Kind := Symbol_Task;
         Flags.Has_Task_Type_Metadata := True;
         Set_Name (Read_Name (Decl, Decl'First + 10, True));
      elsif Starts_With_Word (Decl_Lower, "task") then
         Kind := Symbol_Task;
         Set_Name (Read_Name (Decl, Decl'First + 4, True));
      elsif Starts_With (Decl_Lower, "protected body ") then
         Kind := Symbol_Protected;
         Set_Name (Read_Name (Decl, Decl'First + 15, True));
      elsif Starts_With (Decl_Lower, "protected type ") then
         Kind := Symbol_Protected;
         Flags.Has_Protected_Type_Metadata := True;
         Set_Name (Read_Name (Decl, Decl'First + 15, True));
      elsif Starts_With_Word (Decl_Lower, "protected") then
         Kind := Symbol_Protected;
         Set_Name (Read_Name (Decl, Decl'First + 9, True));
      elsif Starts_With_Word (Decl_Lower, "entry") then
         Kind := Symbol_Entry;
         Flags.Has_Entry_Family_Metadata := Has_Entry_Family_Metadata (Decl);
         Set_Name (Read_Name (Decl, Decl'First + 5, True));
         if State.Name_Len > 0 then
            Set_Profile (Profile_From (Decl, Current_Name));
         end if;
      elsif Flags.Is_Rename
        and then Has_Declaration_Colon (Decl_Lower)
        and then Has_Code_Char (Decl_Lower, ';')
      then
         Declaration_Collectors.Add_Object_Rename_Declaration_Groups
           (Analysis, Decl, Line_Number, Depth, Parent);
         return True;
      elsif Flags.Is_Rename
        and then Has_Declaration_Colon (Decl_Lower)
        and then not Has_Code_Char (Decl_Lower, ';')
      then
         if Ada.Strings.Fixed.Index (Decl_Lower, ": exception") /= 0 then
            Kind := Symbol_Exception;
         elsif Has_Object_Constant_Qualifier (Decl) then
            Kind := Symbol_Constant;
         else
            Kind := Symbol_Object;
         end if;
         Set_Name (Read_Name (Decl, Decl'First, True));
         Set_Target (Target_After (Decl, "renames"));
      elsif (Targets.Pending_Generic or else Kind = Symbol_Unknown)
        and then Handle_Object_Declaration_Line
          (Analysis, Raw_Line, Decl, Decl_Lower, Line_Number, Depth,
           Parent, Flags, Targets)
      then
         return True;
      end if;

      return False;
   end Recognize_Declaration_Line;

   function Handle_Same_Line_Declaration_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Decl            : String;
      Decl_Lower      : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Is_Private      : Boolean;
      Pending_Generic : Boolean;
      Profile         : in out Profile_Context) return Boolean
   is
   begin
      if Same_Line_Declarations.Has_Same_Line_Subtype_Group
        (Raw_Line, Decl_Lower)
      then
         Same_Line_Emitters.Add_Same_Line_Subtype_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent, Is_Private);
         return True;
      elsif Same_Line_Declarations.Has_Same_Line_Type_Group
        (Raw_Line, Decl_Lower)
      then
         Same_Line_Emitters.Add_Same_Line_Type_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Is_Private, Pending_Generic);
         return True;
      elsif Same_Line_Declarations.Has_Same_Line_Package_Group
        (Raw_Line, Decl_Lower, Pending_Generic)
      then
         Same_Line_Emitters.Add_Same_Line_Package_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Is_Private, Pending_Generic);
         return True;
      elsif Same_Line_Declarations.Has_Same_Line_Callable_Group (Raw_Line) then
         Same_Line_Emitters.Add_Same_Line_Callable_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Is_Private, Pending_Generic,
            Profile.Pending_Profile_Access_Target_Owners,
            Profile.Pending_Profile_Access_Target_Count);
         return True;
      elsif Same_Line_Declarations.Has_Same_Line_Concurrent_Group
        (Raw_Line, Decl, Decl_Lower)
      then
         Same_Line_Emitters.Add_Same_Line_Concurrent_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Is_Private,
            Profile.Pending_Profile_Access_Target_Owners,
            Profile.Pending_Profile_Access_Target_Count);
         return True;
      else
         return False;
      end if;
   end Handle_Same_Line_Declaration_Groups;

end Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase;
