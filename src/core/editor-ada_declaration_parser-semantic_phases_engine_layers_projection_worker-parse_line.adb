with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Generic_Tail_Phase;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
with Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase;
with Editor.Ada_Declaration_Parser.Line_Dispatch;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase;
with Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase;
with Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Ada_Declaration_Parser.Representation_Static_Values;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Language_Model;
with Editor.Ada_Symbol_Resolver;

use Editor.Ada_Language_Model;
use Editor.Text_Helpers;
use Editor.Ada_Declaration_Parser.Lexical_Helpers;
use Editor.Ada_Declaration_Parser.Source_Awareness;
use Editor.Ada_Declaration_Parser.Metadata_Helpers;
use Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
separate (Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker)
   procedure Parse_Line
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Context     : in out Parse_Line_Context)
   is
      Scope_State renames Context.Scope;
      Declaration_Targets renames Context.Declaration_Targets;
      Profile_State renames Context.Profile;
      Executable_Binding renames Context.Executable_Binding;
      Source_Recovery renames Context.Source_Recovery;

      Depth           : Natural renames Scope_State.Depth;
      Pending_Generic : Boolean renames Declaration_Targets.Pending_Generic;
      In_Record       : Boolean renames Scope_State.In_Record;
      Pending_Discriminants : Boolean renames Declaration_Targets.Pending_Discriminants;
      Pending_Discriminant_Owner : Symbol_Id renames Declaration_Targets.Pending_Discriminant_Owner;
      Pending_Type_Header_Owner : Symbol_Id renames Declaration_Targets.Pending_Type_Header_Owner;
      Pending_Record_After_Is_Owner : Symbol_Id renames Declaration_Targets.Pending_Record_After_Is_Owner;
      Pending_Concurrent_Header_Owner : Symbol_Id renames Declaration_Targets.Pending_Concurrent_Header_Owner;
      Pending_Array_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Array_Target_Owner;
      Pending_Access_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Access_Target_Owner;
      Pending_Access_Subprogram_Profile_Owner : Symbol_Id renames Declaration_Targets.Pending_Access_Subprogram_Profile_Owner;
      Pending_Return_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Return_Target_Owner;
      Pending_Return_Access_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Return_Access_Target_Owner;
      Pending_Subtype_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Subtype_Target_Owner;
      Pending_Derived_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Derived_Target_Owner;
      Pending_Interface_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Interface_Target_Owner;
      Pending_Declaration_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Declaration_Target_Owner;
      Pending_Generic_Formal_Package_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Generic_Formal_Package_Target_Owner;
      Pending_Generic_Formal_Subprogram_Target_Owner : Symbol_Id renames Declaration_Targets.Pending_Generic_Formal_Subprogram_Target_Owner;
      Pending_Object_Array_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Array_Target_Owners;
      Pending_Object_Array_Target_Count  : Natural renames Declaration_Targets.Pending_Object_Array_Target_Count;
      Pending_Object_Access_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Access_Target_Owners;
      Pending_Object_Access_Target_Count  : Natural renames Declaration_Targets.Pending_Object_Access_Target_Count;
      Pending_Object_Access_Subprogram_Profile_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Object_Access_Subprogram_Profile_Owners;
      Pending_Object_Access_Subprogram_Profile_Count  : Natural renames Declaration_Targets.Pending_Object_Access_Subprogram_Profile_Count;
      Pending_Generic_Formal_Object_Target_Owners : Collected_Symbol_List renames Declaration_Targets.Pending_Generic_Formal_Object_Target_Owners;
      Pending_Generic_Formal_Object_Target_Count  : Natural renames Declaration_Targets.Pending_Generic_Formal_Object_Target_Count;
      Pending_Profile_Access_Target_Owners : Collected_Symbol_List renames Profile_State.Pending_Profile_Access_Target_Owners;
      Pending_Profile_Access_Target_Count  : Natural renames Profile_State.Pending_Profile_Access_Target_Count;
      Pending_Enumeration : Boolean renames Executable_Binding.Pending_Enumeration;
      Pending_Enumeration_Owner : Symbol_Id renames Executable_Binding.Pending_Enumeration_Owner;
      Pending_Profile : Boolean renames Profile_State.Pending_Profile;
      Pending_Profile_Owner : Symbol_Id renames Profile_State.Pending_Profile_Owner;
      Pending_Body_Owner : Symbol_Id renames Executable_Binding.Pending_Body_Owner;
      No_Comment : constant String := Editor.Ada_Syntax_Core.Strip_Comment_Safely (Raw_Line);
      Trimmed    : constant String := Trim (No_Comment);
      Lower_Line : constant String := Lower (Trimmed);
      Decl       : constant String := Strip_Prefixes (Trimmed);
      Raw_Decl   : constant String := Strip_Prefixes (Trim (Raw_Line));
      Decl_Lower : constant String := Lower (Decl);
      Phase_State : Parse_Line_Phase_State;
      Name        renames Phase_State.Name;
      Name_Len    renames Phase_State.Name_Len;
      Kind        renames Phase_State.Kind;
      Flags       renames Phase_State.Flags;
      Target      renames Phase_State.Target;
      Target_Len  renames Phase_State.Target_Len;
      Profile     renames Phase_State.Profile;
      Profile_Len renames Phase_State.Profile_Len;

      procedure Set_Target (S : String) is
      begin
         Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Set_Target
           (Phase_State, S);
      end Set_Target;

      function Current_Name return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Name_Text
           (Phase_State);
      end Current_Name;

      function Current_Target return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Target_Text
           (Phase_State);
      end Current_Target;

      function Current_Profile return String is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Phase_States.Profile_Text
           (Phase_State);
      end Current_Profile;

      function Current_Parent return Symbol_Id is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase.Current_Parent
           (Scope_State);
      end Current_Parent;

      function Current_Private return Boolean is
      begin
         return Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase.Current_Private
           (Scope_State);
      end Current_Private;

      function Starts_With_Declaration_Or_Metadata return Boolean is
      begin
         return Line_Dispatch.Starts_With_Declaration_Or_Metadata
           (Decl_Lower);
      end Starts_With_Declaration_Or_Metadata;

      function Emit return Symbol_Id is
         Col : constant Positive := First_Non_Blank_Column (Raw_Line);
         Parent : constant Symbol_Id := Current_Parent;
         Final_Kind : Symbol_Kind := Kind;
      begin
         if Name_Len = 0 then
            return No_Symbol;
         end if;
         if Pending_Generic then
            Flags.Is_Generic := True;
            if Kind = Symbol_Generic_Formal_Type
              or else Kind = Symbol_Generic_Formal_Object
              or else Kind = Symbol_Generic_Formal_Subprogram
              or else Kind = Symbol_Generic_Formal_Package
            then
               null;
            elsif Kind = Symbol_Package then
               Final_Kind := Symbol_Generic_Package;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            elsif Kind = Symbol_Procedure or else Kind = Symbol_Function or else Kind = Symbol_Operator_Function then
               Final_Kind := Symbol_Generic_Subprogram;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            else
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            end if;
         end if;

         if Flags.Is_Separate
           and then Has_Token (Decl_Lower, "is")
           and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Rename
           and then not Flags.Is_Instantiation
           and then (Kind = Symbol_Package_Body
                     or else Kind = Symbol_Procedure
                     or else Kind = Symbol_Function
                     or else Kind = Symbol_Operator_Function
                     or else Kind = Symbol_Task
                     or else Kind = Symbol_Protected)
         then
            --  Keep explicit separate-body metadata in the shared model.
            --  The original callable/package/task kind is still visible from
            --  source spelling/profile/target, while Outline can render this
            --  as a subunit body and navigation can link it to Target_Name.
            Final_Kind := Symbol_Separate_Body;
         end if;

         declare
            New_Id : constant Symbol_Id := Add_Symbol
              (Analysis, Current_Name, Final_Kind,
               (Line_Number, Col, Line_Number, Positive'Max (Col, Col + Name_Len - 1)),
               Col, Enclosing_Scope => Scope_Id (Natural (Parent)),
               Parent_Symbol => Parent, Depth => Depth,
               Profile_Summary => Current_Profile,
               Flags => Flags,
               Target_Name => Current_Target);
         begin
            return New_Id;
         end;
      end Emit;


      procedure Parse_Line_Segment
        (Analysis    : in out Analysis_Result;
         Raw_Line    : String;
         Line_Number : Positive;
         Context     : in out Parse_Line_Context)
      is
      begin
         Parse_Line (Analysis, Raw_Line, Line_Number, Context);
      end Parse_Line_Segment;

      procedure Parse_Compact_Scope_Tail_Impl is new
        Editor.Ada_Declaration_Parser.Parse_Line_Compact_Scope_Phase
          .Parse_Compact_Scope_Tail
            (Parse_Line => Parse_Line_Segment);

      procedure Parse_Compact_Scope_Tail (Owner : Symbol_Id) is
      begin
         Parse_Compact_Scope_Tail_Impl
           (Analysis, Raw_Line, Line_Number, Depth, Owner, Context);
      end Parse_Compact_Scope_Tail;

      procedure Parse_Compact_Record_Tail (Owner : Symbol_Id) is
      begin
         Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase.Parse_Compact_Record_Tail
           (Analysis, Raw_Line, Line_Number, Depth, Owner,
            Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata'Access);
      end Parse_Compact_Record_Tail;

      procedure Parse_Record_Opener_Component_Tail (Owner : Symbol_Id) is
         Code         : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Lower_Code   : constant String := Lower (Code);
         Record_Start : Natural := 0;
      begin
         for I in Lower_Code'Range loop
            if Tail_Analysis_Helpers.Tail_Token_At (Lower_Code, I, "record") then
               Record_Start := I;
               exit;
            end if;
         end loop;

         if Record_Start = 0 or else Record_Start + 6 > Raw_Line'Last then
            return;
         end if;

         declare
            Tail_Line : String := Raw_Line;
         begin
            for I in Tail_Line'First .. Record_Start + 5 loop
               Tail_Line (I) := ' ';
            end loop;

            if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length /= 0 then
               Declaration_Collectors.Add_Record_Component_Names
                 (Analysis, Tail_Line, Line_Number,
                  Natural'Min (Depth + 1, Max_Scope_Nesting), Owner,
                  Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata'Access);
            end if;
         end;
      end Parse_Record_Opener_Component_Tail;

      function Strip_Leading_Statement_Labels (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Statement_Labels;

      function Strip_Leading_Named_Statement_Prefix (Text : String) return String
        renames Tail_Analysis_Helpers.Strip_Leading_Named_Statement_Prefix;

      procedure Mark_Statement_Awareness is
      begin
         Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker.Statement_Awareness.Mark_Statement_Awareness
           (Analysis, Lower_Line, Trimmed, In_Record);
      end Mark_Statement_Awareness;

   begin
      Mark_Source_Awareness (Analysis, Raw_Line);

      if Trimmed'Length = 0 then
         if Pending_Enumeration then
            Add_Enumeration_Literals_Continuation
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               (if Pending_Enumeration_Owner /= No_Symbol then
                   Pending_Enumeration_Owner
                else
                   Current_Parent));
            if Ada.Strings.Fixed.Index (Lower (Raw_Line), ")") /= 0 then
               Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                 .Clear_Pending_Enumeration (Executable_Binding);
            end if;
         end if;
         return;
      end if;

      Mark_Statement_Awareness;

      if Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
           .Handle_Pending_Aspect_Line
             (Analysis, Source_Recovery, Raw_Line, Lower_Line, Line_Number)
      then
         return;
      end if;

      Mark_Context_Clause_Awareness
        (Analysis, Raw_Line, Line_Number,
         Scope_Id (Natural (Current_Parent)));

      if In_Record
        and then Starts_With_Word (Lower_Line, "case")
        and then Has_Token (Lower_Line, "is")
      then
         --  Variant parts are record-shape metadata owned by the enclosing
         --  record type.  The discriminant choice expressions and branch
         --  labels are not learned as standalone declarations here.
         Editor.Ada_Language_Model.Mark_Symbol_Variant_Record_Metadata
           (Analysis, Current_Parent);
         return;
      end if;

      Representation_Metadata.Mark_Representation_Clause_Target (Analysis, Raw_Line);
      Mark_Pragma_Target
        (Analysis, Raw_Line,
         Current_Parent);

      declare
         Code        : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Private_End : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = ';' then
               Private_End := I;
               exit;
            end if;
         end loop;

         if Private_End /= 0
           and then Private_End > Code'First
           and then Lower (Trim (Code (Code'First .. Private_End - 1))) = "private"
           and then Private_End < Raw_Line'Last
         then
            declare
               Tail_Line : String := Raw_Line;
            begin
               for I in Tail_Line'First .. Private_End loop
                  Tail_Line (I) := ' ';
               end loop;

               if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length /= 0 then
                  --  Compact/generated Ada may put a package private-section
                  --  marker and the first private declaration on the same
                  --  physical line.  Mark the current scope private first,
                  --  then reparse the tail with absolute source columns
                  --  preserved by blanking the consumed prefix.
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Mark_Current_Private (Scope_State);
                  declare
                     Segment_Start : Natural := Private_End + 1;
                     Nesting       : Natural := 0;

                     procedure Parse_Private_Segment (First, Last : Natural) is
                        Segment_Line : String := (Raw_Line'Range => ' ');
                     begin
                        if First > Last then
                           return;
                        end if;
                        Segment_Line (First .. Last) := Raw_Line (First .. Last);
                        if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Segment_Line))'Length = 0 then
                           return;
                        end if;
                        Parse_Line (Analysis, Segment_Line, Line_Number, Context);
                     end Parse_Private_Segment;
                  begin
                     for I in Segment_Start .. Code'Last loop
                        if Code (I) = '(' then
                           Nesting := Nesting + 1;
                        elsif Code (I) = ')' then
                           if Nesting > 0 then
                              Nesting := Nesting - 1;
                           end if;
                        elsif Code (I) = ';' and then Nesting = 0 then
                           Parse_Private_Segment (Segment_Start, I);
                           Segment_Start := I + 1;
                        end if;
                     end loop;

                     if Segment_Start <= Raw_Line'Last then
                        Parse_Private_Segment (Segment_Start, Raw_Line'Last);
                     end if;
                  end;
                  return;
               end if;
            end;
         end if;
      end;

      if Lower_Line = "private" or else Lower_Line = "private;" then
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Mark_Current_Private (Scope_State);
         return;
      end if;

      if Starts_With (Lower_Line, "end record") then
         --  Representation clauses use "for T use record ... end record;"
         --  without opening a language-model scope.  Only close a parser
         --  record scope when the parser is actually inside a record type.
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Close_Record_Scope (Scope_State);
         Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase
           .Clear_After_Scope_Close (Context);
         return;
      end if;

      if Is_Scope_End (Lower_Line) then
         Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
           .Leave_Scope (Scope_State);
         Editor.Ada_Declaration_Parser.Parse_Line_Pending_Phase
           .Clear_After_Scope_Close (Context);
         return;
      end if;

      if Pending_Array_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Array_Target_From_Line (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Array_Target_Owner, Target);
            end if;
         end;

         Pending_Array_Target_Owner := No_Symbol;
         return;
      end if;

      if Pending_Access_Target_Owner /= No_Symbol then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Access_Target_Owner, Target);
               if Pending_Access_Subprogram_Profile_Owner = Pending_Access_Target_Owner then
                  Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               end if;
               Pending_Access_Target_Owner := No_Symbol;
               return;
            elsif Profile'Length /= 0
              and then Pending_Access_Subprogram_Profile_Owner = Pending_Access_Target_Owner
            then
               Set_Symbol_Profile (Analysis, Pending_Access_Target_Owner, Profile);
               Mark_Symbol_Access_Subprogram_Metadata
                 (Analysis, Pending_Access_Target_Owner);
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               Pending_Access_Target_Owner := No_Symbol;
               return;
            else
               Pending_Access_Target_Owner := No_Symbol;
            end if;
         end;
      end if;

      if Pending_Access_Subprogram_Profile_Owner /= No_Symbol then
         declare
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               Set_Symbol_Profile
                 (Analysis, Pending_Access_Subprogram_Profile_Owner, Profile);
               Mark_Symbol_Access_Subprogram_Metadata
                 (Analysis, Pending_Access_Subprogram_Profile_Owner);
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Access_Subprogram_Profile_Owner := No_Symbol;
               return;
            else
               --  Split access-to-subprogram type declarations may put the
               --  callable profile on a continuation line:
               --     type Callback is access
               --        procedure (Item : Element);
               --  Keep those lines as type metadata so they do not become
               --  false declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Return_Access_Target_Owner /= No_Symbol then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
            Owner   : constant Symbol_Id := Pending_Return_Access_Target_Owner;

            procedure Clear_Pending_Profile_For_Owner is
            begin
               if Pending_Profile_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Clear_Pending_Profile (Profile_State);
               end if;
            end Clear_Pending_Profile_For_Owner;
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Owner, Target);
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner
                 and then Has_Code_Char (Lower_Line, ';')
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            elsif Profile'Length /= 0 then
               Set_Symbol_Profile
                 (Analysis, Owner, Profile);
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner
                 and then Has_Code_Char (Lower_Line, ';')
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               if Pending_Return_Target_Owner = Owner then
                  Pending_Return_Target_Owner := No_Symbol;
               end if;
               Clear_Pending_Profile_For_Owner;
               if Pending_Body_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
               Pending_Return_Access_Target_Owner := No_Symbol;
               return;
            else
               --  Split anonymous access result declarations may put access
               --  qualifiers on one continuation line and either a designated
               --  subtype or callable profile on a later line:
               --     function Ref return access
               --        all Root'Class;
               --     function Handler return access
               --        procedure (Item : Element);
               --  Keep those lines as callable result metadata only.
               return;
            end if;
         end;
      end if;

      if Pending_Return_Target_Owner /= No_Symbol and then not Pending_Profile then
         declare
            Target : constant String := Return_Target_From_Line_Start (Raw_Line);
            Owner  : constant Symbol_Id := Pending_Return_Target_Owner;
         begin
            if Ada.Strings.Fixed.Index (Lower_Line, "return") /= 0
              and then Has_Token (Lower_Line, "access")
              and then not Has_Code_Char (Lower_Line, ';')
            then
               Pending_Return_Access_Target_Owner := Owner;
               return;
            elsif Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Target);
               Pending_Return_Target_Owner := No_Symbol;
               if Has_Code_Char (Lower_Line, ';') then
                  return;
               end if;
            elsif Has_Code_Char (Lower_Line, ';') or else Has_Token (Lower_Line, "is") then
               Pending_Return_Target_Owner := No_Symbol;
            else
               --  Keep waiting across harmless split return-subtype
               --  continuations, but do not treat those lines as separate
               --  declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Subtype_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Subtype_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Subtype_Target_Owner, Target);
               Pending_Subtype_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Subtype_Target_Owner := No_Symbol;
               return;
            else
               --  Split subtype declarations can put the subtype mark on a
               --  continuation line before range/aspect/default metadata:
               --     subtype Index is
               --        Positive range 1 .. 10;
               --  Keep those continuation lines as subtype metadata rather
               --  than parsing them as declarations in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Declaration_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Declaration_Target_From_Line_Start (Raw_Line);
            Owner  : constant Symbol_Id := Pending_Declaration_Target_Owner;

            procedure Clear_Pending_Profile_For_Owner is
            begin
               if Pending_Profile_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Clear_Pending_Profile (Profile_State);
               end if;
               if Pending_Body_Owner = Owner then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Clear_Pending_Body (Executable_Binding);
               end if;
            end Clear_Pending_Profile_For_Owner;
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Owner, Target);
               Clear_Pending_Profile_For_Owner;
               Pending_Declaration_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Clear_Pending_Profile_For_Owner;
               Pending_Declaration_Target_Owner := No_Symbol;
               return;
            else
               --  Split renames/instantiations may put the renamed or
               --  generic unit name on a continuation line:
               --     package IO is new
               --        Ada.Text_IO.Integer_IO;
               --  Keep the continuation as declaration metadata so it does
               --  not become a false package-level declaration.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Subprogram_Target_Owner /= No_Symbol then
         declare
            Target : constant String :=
              Generic_Formal_Subprogram_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Pending_Generic_Formal_Subprogram_Target_Owner, Target);
               Pending_Generic_Formal_Subprogram_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Subprogram_Target_Owner := No_Symbol;
               return;
            else
               --  Split generic formal subprogram defaults may place the
               --  default callable name after a later "is" line.  Keep
               --  those continuation lines as formal metadata so they do not
               --  become ordinary declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Package_Target_Owner /= No_Symbol then
         declare
            Target : constant String :=
              Generic_Formal_Package_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target
                 (Analysis, Pending_Generic_Formal_Package_Target_Owner, Target);
               Mark_Symbol_Instantiation
                 (Analysis, Pending_Generic_Formal_Package_Target_Owner);
               Pending_Generic_Formal_Package_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Package_Target_Owner := No_Symbol;
               return;
            else
               --  Split generic formal package declarations can put the
               --  "is new" phrase or the instantiated unit on a later line:
               --     with package Maps is
               --        new Ada.Containers.Ordered_Maps;
               --  Keep those lines as generic-formal metadata so they do not
               --  become false package-level declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Array_Target_Count > 0 then
         declare
            Target : constant String := Array_Target_From_Line (Raw_Line);
         begin
            if Target'Length /= 0 then
               for I in 1 .. Pending_Object_Array_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Object_Array_Target_Owners (I), Target);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Array_Targets (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Array_Targets (Declaration_Targets);
               return;
            else
               --  Split anonymous array object declarations may put the
               --  index constraint on one continuation line and the element
               --  subtype after "of" on a later line.  Treat those lines as
               --  declaration metadata until the target is found or the
               --  declaration terminates.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Access_Target_Count > 0 then
         declare
            Target  : constant String := Access_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Target'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Object_Access_Target_Owners (I), Target);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            elsif Profile'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Target_Count loop
                  Set_Symbol_Profile
                    (Analysis, Pending_Object_Access_Target_Owners (I), Profile);
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Targets (Declaration_Targets);
               return;
            else
               --  Split anonymous access object/subprogram declarations may
               --  place null/all/constant/designated-subtype qualifiers or a
               --  callable profile on a continuation line.  Keep those lines
               --  as declaration metadata so they do not create false
               --  package-level symbols.
               return;
            end if;
         end;
      end if;

      if Pending_Object_Access_Subprogram_Profile_Count > 0 then
         declare
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               for I in 1 .. Pending_Object_Access_Subprogram_Profile_Count loop
                  Set_Symbol_Profile
                    (Analysis,
                     Pending_Object_Access_Subprogram_Profile_Owners (I),
                     Profile);
                  Mark_Symbol_Access_Subprogram_Metadata
                    (Analysis,
                     Pending_Object_Access_Subprogram_Profile_Owners (I));
               end loop;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Subprogram_Profiles
                   (Declaration_Targets);
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Start_Pending_Object_Access_Subprogram_Profiles
                   (Declaration_Targets);
               return;
            else
               --  Split anonymous access-to-subprogram object declarations
               --  can put the callable profile on a later continuation line:
               --     Handler : access
               --        procedure (Item : Element);
               --  Keep those lines as object-type metadata so profile
               --  parameters do not become package-level declarations.
               return;
            end if;
         end;
      end if;

      if Pending_Generic_Formal_Object_Target_Count > 0 then
         declare
            Target  : constant String := Object_Target_From_Line_Start (Raw_Line);
            Profile : constant String := Access_Subprogram_Profile (Raw_Line);
         begin
            if Profile'Length /= 0 then
               for I in 1 .. Pending_Generic_Formal_Object_Target_Count loop
                  Set_Symbol_Profile
                    (Analysis, Pending_Generic_Formal_Object_Target_Owners (I), Profile);
               end loop;
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            elsif Target'Length /= 0 then
               for I in 1 .. Pending_Generic_Formal_Object_Target_Count loop
                  Set_Symbol_Target
                    (Analysis, Pending_Generic_Formal_Object_Target_Owners (I), Target);
               end loop;
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Generic_Formal_Object_Target_Owners := (others => No_Symbol);
               Pending_Generic_Formal_Object_Target_Count := 0;
               return;
            else
               --  Split generic formal object declarations may put mode
               --  keywords, subtype marks, or anonymous access-to-subprogram
               --  profiles on later lines.  Keep those lines as
               --  formal-declaration metadata rather than learning them as
               --  ordinary package-level objects.
               return;
            end if;
         end;
      end if;

      if Pending_Interface_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Interface_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Interface_Target_Owner, Target);
               Pending_Interface_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Interface_Target_Owner := No_Symbol;
               return;
            else
               --  Split interface declarations can put the parent interface
               --  after a trailing "and" on a continuation line:
               --     type Child is limited interface and
               --        Root;
               --  Treat that continuation as type metadata instead of a
               --  standalone declaration in the enclosing scope.
               return;
            end if;
         end;
      end if;

      if Pending_Derived_Target_Owner /= No_Symbol then
         declare
            Target : constant String := Derived_Target_From_Line_Start (Raw_Line);
         begin
            if Target'Length /= 0 then
               Set_Symbol_Target (Analysis, Pending_Derived_Target_Owner, Target);
            end if;

            if Has_Token (Lower_Line, "record") then
               --  Split derived record extensions can place both the parent
               --  subtype and the record opener on the continuation line:
               --     type Child is new
               --        Parent with record
               --  Stamp the parent target and open the record scope from the
               --  same metadata line rather than learning it as a declaration.
               Set_Symbol_Kind (Analysis, Pending_Derived_Target_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Derived_Target_Owner);
               Pending_Record_After_Is_Owner := No_Symbol;
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            elsif Has_Code_Char (Lower_Line, ';') then
               Pending_Record_After_Is_Owner := No_Symbol;
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            else
               --  Keep intermediate derived-type metadata lines from being
               --  interpreted as standalone declarations.
               Pending_Derived_Target_Owner := No_Symbol;
               return;
            end if;
         end;
      end if;

      if Pending_Record_After_Is_Owner /= No_Symbol then
         if Has_Token (Lower_Line, "record") then
            --  Handle Ada style split over the body opener:
            --     type Rec is
            --        record
            --  The first line has already emitted the type symbol; the
            --  record line upgrades it and opens the record scope so
            --  subsequent components are owned by the record type.
            Set_Symbol_Kind (Analysis, Pending_Record_After_Is_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Record_After_Is_Owner);
            Pending_Record_After_Is_Owner := No_Symbol;
            return;
         else
            --  If the continuation is not a record opener, stop treating it
            --  as a split record header and let normal declaration parsing
            --  inspect the line.  This keeps incomplete/other type forms
            --  conservative rather than swallowing valid declarations.
            Pending_Record_After_Is_Owner := No_Symbol;
         end if;
      end if;

      if Pending_Type_Header_Owner /= No_Symbol then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0
           and then Ada.Strings.Fixed.Index (Lower_Line, "(") /= 0
         then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Type_Header_Owner);
            Pending_Discriminants := Ada.Strings.Fixed.Index (Lower_Line, ")") = 0;
            Pending_Discriminant_Owner := Pending_Type_Header_Owner;
         elsif Pending_Discriminants
           and then Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0
         then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Type_Header_Owner);
         end if;

         if Has_Token (Lower_Line, "record") then
            Set_Symbol_Kind (Analysis, Pending_Type_Header_Owner, Symbol_Record_Type);
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Open_Record_Scope (Scope_State, Pending_Type_Header_Owner);
            Pending_Type_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
            return;
         elsif Has_Code_Char (Lower_Line, ';') and then not Pending_Discriminants then
            Pending_Type_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         elsif Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;

         return;
      end if;

      if Pending_Concurrent_Header_Owner /= No_Symbol then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            Add_Discriminant_Names
              (Analysis, Raw_Line, Line_Number, Depth + 1,
               Pending_Concurrent_Header_Owner);
            Pending_Discriminants := Ada.Strings.Fixed.Index (Lower_Line, ")") = 0;
            Pending_Discriminant_Owner := Pending_Concurrent_Header_Owner;
         end if;

         if Has_Token (Lower_Line, "is")
           and then not Has_Code_Char (Lower_Line, ';')
         then
            Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
              .Enter_Scope (Scope_State, Pending_Concurrent_Header_Owner);
            Pending_Concurrent_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
            return;
         elsif Has_Code_Char (Lower_Line, ';') and then not Pending_Discriminants then
            Pending_Concurrent_Header_Owner := No_Symbol;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         elsif Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;

         return;
      end if;

      if Pending_Discriminants then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            Add_Discriminant_Names (Analysis, Raw_Line, Line_Number, Depth + 1,
                                    (if Pending_Discriminant_Owner /= No_Symbol then
                                        Pending_Discriminant_Owner
                                      else
                                        Current_Parent));
         end if;
         if Ada.Strings.Fixed.Index (Lower_Line, ")") /= 0 then
            if Has_Token (Lower_Line, "record") then
               if Pending_Discriminant_Owner /= No_Symbol then
                  Set_Symbol_Kind
                    (Analysis, Pending_Discriminant_Owner, Symbol_Record_Type);
               end if;
               if Pending_Discriminant_Owner /= No_Symbol then
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Open_Record_Scope (Scope_State, Pending_Discriminant_Owner);
               else
                  Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                    .Set_In_Record (Scope_State, True);
               end if;
            end if;
            Pending_Discriminants := False;
            Pending_Discriminant_Owner := No_Symbol;
         end if;
         return;
      end if;

      if Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
        .Handle_Executable_Continuation
          (Analysis, Raw_Line, Lower_Line, Line_Number, Depth,
           Current_Parent, Starts_With_Declaration_Or_Metadata,
           Declaration_Targets, Executable_Binding, Scope_State)
      then
         return;
      end if;

      if Pending_Profile then
         Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
           .Handle_Pending_Profile_Continuation
             (Analysis, Raw_Line, Lower_Line, Line_Number, Depth,
              Profile_State, Declaration_Targets, Executable_Binding,
              Scope_State);
         return;
      end if;

      if In_Record then
         if Ada.Strings.Fixed.Index (Lower_Line, ":") /= 0 then
            --  Record components may split their default expression or
            --  aspect clause away from the subtype line:
            --     Child : Root'Class
            --        := Default;
            --  Learn the component from the owning declaration line and
            --  leave the continuation as metadata-only.
            Add_Record_Component_Names
              (Analysis, Raw_Line, Line_Number, Depth,
               Current_Parent);
            return;
         end if;
      end if;

      if Starts_With_Word (Lower_Line, "generic") then
         Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
           .Begin_Generic (Declaration_Targets);

         declare
            function Parse_Generic_Segment
              (First : Natural;
               Last  : Natural) return Boolean
            is
               Segment_Line : String := (Raw_Line'Range => ' ');
            begin
               if First > Last then
                  return False;
               end if;

               Segment_Line (First .. Last) := Raw_Line (First .. Last);
               if Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Segment_Line))'Length = 0 then
                  return False;
               end if;

               Parse_Line (Analysis, Segment_Line, Line_Number, Context);
               return True;
            end Parse_Generic_Segment;

            procedure Parse_Generic_Tail is new
              Editor.Ada_Declaration_Parser.Generic_Tail_Phase.Parse_Same_Line_Generic_Tail
                (Parse_Segment => Parse_Generic_Segment);
         begin
            Parse_Generic_Tail (Raw_Line);
         end;

         return;
      end if;

      if Starts_With_Word (Lower_Line, "separate") then
         declare
            Code  : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
            Close : Natural := 0;
         begin
            for I in Code'Range loop
               if Code (I) = ')' then
                  Close := I;
                  exit;
               end if;
            end loop;

            if Close /= 0 and then Close < Raw_Line'Last then
               declare
                  Tail_Line : String := Raw_Line;
               begin
                  for I in Tail_Line'First .. Close loop
                     Tail_Line (I) := ' ';
                  end loop;

                  declare
                     Tail_Code : constant String :=
                       Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line));
                  begin
                     if Tail_Code'Length /= 0 then
                        --  Compact/generated Ada can put the separate parent
                        --  marker and the following body declaration on the
                        --  same physical line.  Preserve absolute source
                        --  columns by blanking the consumed prefix, then parse
                        --  the body with Pending_Separate_Target set.
                        Editor.Ada_Declaration_Parser
                          .Parse_Line_Source_Recovery_Phase
                          .Set_Pending_Separate_Target
                            (Source_Recovery, Separate_Parent_Name (Trimmed));
                        Parse_Line (Analysis, Tail_Line, Line_Number, Context);
                        return;
                     end if;
                  end;
               end;
            end if;
         end;
      end if;

      if Starts_With_Word (Lower_Line, "separate")
        and then Ada.Strings.Fixed.Index (Lower_Line, ")") = Lower_Line'Last
      then
         Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
           .Set_Pending_Separate_Target
             (Source_Recovery, Separate_Parent_Name (Trimmed));
         return;
      end if;

      Flags.Is_Private := Starts_With (Lower_Line, "private ")
        or else Current_Private
        or else (Starts_With_Word (Decl_Lower, "type")
                 and then Has_Token (Decl_Lower, "private"));
      Flags.Is_Abstract := Starts_With (Lower_Line, "abstract ") or else Ada.Strings.Fixed.Index (Lower_Line, " abstract ") /= 0;
      Flags.Is_Overriding := Starts_With (Lower_Line, "overriding ");
      Flags.Is_Not_Overriding := Starts_With (Lower_Line, "not overriding ");
      Flags.Is_Separate := Starts_With_Word (Lower_Line, "separate")
        or else Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
          .Has_Pending_Separate_Target (Source_Recovery)
        or else (Has_Token (Lower_Line, "is")
                 and then Has_Token (Lower_Line, "separate"));
      Flags.Has_Aspect_Specification := Metadata_Helpers.Has_Aspect_Specification (Trimmed);
      Flags.Has_Null_Exclusion := Has_Null_Exclusion (Trimmed);
      Flags.Has_Aliased_Metadata := Has_Aliased_Metadata (Trimmed);
      Flags.Has_Deferred_Constant_Metadata := Has_Deferred_Constant_Metadata (Trimmed);
      Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase.Mark_Declaration_Form_Metadata (Flags, Trimmed);
      if Starts_With_Word (Lower_Line, "separate") then
         Set_Target (Separate_Parent_Name (Trimmed));
      elsif Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
        .Has_Pending_Separate_Target (Source_Recovery)
      then
         Set_Target
           (Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
              .Consume_Pending_Separate_Target (Source_Recovery));
      end if;
      Flags.Is_Rename := Has_Token (Lower_Line, "renames");
      --  Access-to-subprogram type profiles are type metadata, not
      --  discriminant parts or callable declarations; the type branches
      --  below explicitly exclude access types from discriminant learning.
      --  Instantiation is declaration-family specific.  A derived type such
      --  as "type T is new Parent" contains the Ada keyword "new" but is
      --  not a generic instantiation; set this flag only in package,
      --  procedure, function, and formal-package branches that actually
      --  represent instantiations.
      Flags.Is_Instantiation := False;

      if Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
        .Handle_Same_Line_Declaration_Groups
          (Analysis, Raw_Line, Decl, Decl_Lower, Line_Number, Depth,
           Current_Parent, Flags.Is_Private, Pending_Generic, Profile_State)
      then
         return;
      end if;

      if Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
        .Recognize_Declaration_Line
          (Analysis, Raw_Line, Raw_Decl, Decl, Decl_Lower, Line_Number,
           Depth, Current_Parent, Scope_State, Declaration_Targets,
           Phase_State)
      then
         return;
      end if;

      if Kind /= Symbol_Unknown then
         if (Kind = Symbol_Procedure
             or else Kind = Symbol_Function
             or else Kind = Symbol_Operator_Function)
           and then Has_Token (Decl_Lower, "is")
           and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Instantiation
           and then not Flags.Is_Rename
           and then not Flags.Is_Separate
         then
            --  retain callable body/spec metadata so indexed
            --  Outline navigation can safely pair subprogram declarations
            --  with their bodies instead of treating same-name callables as
            --  indistinguishable overload candidates.
            Flags.Is_Body := True;
         end if;

         if Name_Len > 0
           and then Is_Invalid_Compact_Owner_Name (Current_Name)
         then
            --  keep malformed/in-progress declarations from
            --  learning Ada reserved words as real language-model symbols in
            --  the fallback declaration path as well as in compact tail
            --  splitters.  If the malformed declaration was the generic unit
            --  following a same-line ``generic;`` marker, consume that marker
            --  so later independent declarations are not misclassified as the
            --  generic unit.
            if Pending_Generic
              and then Kind in Symbol_Package | Symbol_Package_Body |
                Symbol_Procedure | Symbol_Function | Symbol_Operator_Function
            then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Consume_Generic_Unit (Declaration_Targets);
            end if;
            return;
         end if;

         declare
            New_Id : constant Symbol_Id := Emit;
         begin
            Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
              .Add_Trailing_Bare_Aspect
                (Analysis, New_Id, Raw_Line, Line_Number);

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Type
              and then Name_Len > 0
            then
               Add_Generic_Formal_Type_Metadata
                 (Analysis, New_Id, Current_Name,
                  Generic_Formal_Type_Family_From_Line (Decl),
                  Target_Type_Text =>
                    Current_Target,
                  Profile_Text =>
                    Current_Profile,
                  Has_Private => Has_Token (Decl_Lower, "private"),
                  Has_Limited => Flags.Has_Limited_Metadata,
                  Has_Tagged => Flags.Has_Tagged_Metadata,
                  Has_Abstract => Flags.Is_Abstract,
                  Has_Synchronized => Flags.Has_Synchronized_Metadata,
                  Has_Interface => Flags.Has_Interface_Metadata,
                  Has_Box => Ada.Strings.Fixed.Index (Decl_Lower, "<>") /= 0,
                  Has_Discriminant_Part =>
                    Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                    and then Ada.Strings.Fixed.Index (Decl_Lower, ":") /= 0,
                  Source_Span => (Line_Number, First_Non_Blank_Column (Raw_Line), Line_Number,
                            Positive'Max (First_Non_Blank_Column (Raw_Line),
                                          First_Non_Blank_Column (Raw_Line) + Name_Len - 1)));
            end if;
            if New_Id /= No_Symbol
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  The next line may be a split aspect specification owned by
               --  this declaration.  Non-aspect continuation lines clear this
               --  pending owner before normal parsing, so incomplete type,
               --  record, profile, and body continuations remain conservative.
               Editor.Ada_Declaration_Parser.Parse_Line_Source_Recovery_Phase
                 .Set_Pending_Aspect_Owner (Source_Recovery, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Package
                        or else Kind = Symbol_Package_Body
                        or else Kind = Symbol_Procedure
                        or else Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Task
                        or else Kind = Symbol_Protected)
              and then Has_Token (Decl_Lower, "is")
              and then Has_Code_Char (Decl_Lower, ';')
              and then not Flags.Is_Instantiation
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
            then
               Parse_Compact_Scope_Tail (New_Id);
            end if;

            if Kind = Symbol_Record_Type
              and then Has_Token (Lower_Line, "record")
            then
               declare
                  Record_Id : Symbol_Id := New_Id;
               begin
                  if Record_Id = No_Symbol and then Name_Len > 0 then
                     Record_Id :=
                       Editor.Ada_Symbol_Resolver.First_Match_In_Scope
                         (Analysis, Current_Name,
                          Current_Parent);
                  end if;

                  if Record_Id /= No_Symbol then
                     if Ada.Strings.Fixed.Index (Lower_Line, "end record") = 0 then
                        Parse_Record_Opener_Component_Tail (Record_Id);
                     end if;
                     Parse_Compact_Record_Tail (Record_Id);
                  end if;
               end;
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Ada.Strings.Fixed.Index (Decl_Lower, "(") = 0
              and then not Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Type_Header (Declaration_Targets, New_Id);
            elsif New_Id /= No_Symbol
              and then Kind = Symbol_Type
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Token (Decl_Lower, "record")
              and then not Has_Token (Decl_Lower, "private")
              and then not Has_Token (Decl_Lower, "access")
              and then not Has_Token (Decl_Lower, "array")
              and then not Has_Token (Decl_Lower, "range")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support:
               --     type Rec is
               --        record
               --  without opening a scope until the record opener is seen.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Record_After_Is
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "new")
              and then Target_Len = 0
              and then not Has_Token (Decl_Lower, "access")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split derived type/formal type declarations:
               --     type Child is new
               --        Parent with private;
               --  The type symbol comes from the header; the continuation
               --  line supplies the parent subtype target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Derived_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Subtype
              and then Target_Len = 0
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split subtype declarations:
               --     subtype Index is
               --        Positive range 1 .. 10;
               --  The subtype symbol is emitted from the header line, while
               --  the following metadata line supplies the target subtype.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Subtype_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "interface")
              and then Has_Token (Decl_Lower, "and")
              and then Target_Len = 0
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split interface parent declarations:
               --     type Child is limited interface and
               --        Root;
               --  The header owns the type symbol; the continuation line
               --  supplies the parent interface target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Interface_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "array")
              and then Target_Len = 0
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split array type declarations:
               --     type Table is array
               --        (Positive range <>) of Element;
               --  The first line owns the type symbol; the continuation line
               --  supplies the component subtype target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Array_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Type
                        or else Kind = Symbol_Generic_Formal_Type)
              and then Has_Token (Decl_Lower, "access")
              and then Target_Len = 0
              and then Profile_Len = 0
              and then not Has_Token (Decl_Lower, "procedure")
              and then not Has_Token (Decl_Lower, "function")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split access-to-object and access-to-subprogram
               --  type declarations.  The continuation line determines
               --  whether to stamp a designated subtype target or a callable
               --  profile.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Access_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram)
              and then Target_Len = 0
              and then Ada.Strings.Fixed.Index (Decl_Lower, " return ") /= 0
              and then Ada.Strings.Fixed.Index (Decl_Lower, " access") /= 0
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split anonymous access result subtypes/profiles:
               --     function Ref return access
               --        all Root'Class;
               --     function Handler return not null access
               --        procedure (Item : Element);
               --  The callable symbol is emitted from the header; the
               --  continuation supplies either the designated subtype target
               --  or callable result profile metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Return_Access_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram)
              and then Target_Len = 0
              and then not Flags.Is_Rename
              and then not Flags.Is_Separate
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Split function result subtype metadata can appear after
               --  the declaration/profile line:
               --     function Make
               --        return Root'Class;
               --  Keep the callable owner pending so the following return
               --  line can update Target_Name without being parsed as a
               --  separate declaration.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Return_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Target_Len = 0
              and then (Flags.Is_Rename or else Flags.Is_Instantiation)
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split rename/instantiation targets:
               --     package Maps is new
               --        Ada.Containers.Ordered_Maps;
               --     procedure Old renames
               --        New_Name;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Declaration_Target (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Package
              and then Target_Len = 0
              and then not Flags.Is_Instantiation
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split generic formal package targets where the
               --  "new" token itself appears on the continuation line:
               --     with package Maps is
               --        new Ada.Containers.Ordered_Maps;
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Generic_Formal_Package_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then Kind = Symbol_Generic_Formal_Subprogram
              and then Target_Len = 0
              and then Has_Token (Decl_Lower, "is")
              and then not Has_Code_Char (Decl_Lower, ';')
            then
               --  Support split generic formal subprogram defaults:
               --     with procedure Visit (Item : Element) is
               --        Default_Visit;
               --  The formal subprogram owns the symbol; the continuation
               --  supplies the default callable target metadata.
               Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                 .Set_Pending_Generic_Formal_Subprogram_Target
                   (Declaration_Targets, New_Id);
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Procedure
                        or else Kind = Symbol_Function
                        or else Kind = Symbol_Operator_Function
                        or else Kind = Symbol_Generic_Formal_Subprogram
                        or else Kind = Symbol_Entry)
            then
               Add_Profile_Parameter_Names
                 (Analysis, Raw_Line, Line_Number, Depth + 1, New_Id,
                  Current_Name,
                  Pending_Profile_Access_Target_Owners,
                  Pending_Profile_Access_Target_Count);
               if Profile_Still_Open (Raw_Line, Current_Name) then
                  Editor.Ada_Declaration_Parser.Parse_Line_Profile_Phase
                    .Set_Pending_Profile (Profile_State, New_Id);
               end if;
            end if;

            if New_Id /= No_Symbol
              and then (Kind = Symbol_Task or else Kind = Symbol_Protected)
            then
               if Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                 and then Ada.Strings.Fixed.Index (Decl_Lower, ":") /= 0
               then
                  --  Ada task/protected types may have discriminant parts:
                  --     task type Worker (Id : Positive) is
                  --     protected type Cache (Size : Positive) is
                  --  Treat those names as discriminants owned by the concurrent
                  --  type symbol rather than as package-level objects.
                  Add_Discriminant_Names
                    (Analysis, Raw_Line, Line_Number, Depth + 1, New_Id);
               end if;

               if not Has_Token (Decl_Lower, "is")
                 and then not Has_Code_Char (Decl_Lower, ';')
               then
                  --  Split concurrent type headers can put either the whole
                  --  discriminant part or no discriminant part before the later
                  --  body-opening "is":
                  --     task type Worker (Id : Positive)
                  --     is
                  --  Keep the concurrent owner pending so entries/protected
                  --  operations after the later "is" are parented to the
                  --  task/protected type rather than the enclosing package.
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Set_Pending_Concurrent_Header
                      (Declaration_Targets, New_Id);
               end if;
            end if;

            if Pending_Discriminants and then Pending_Discriminant_Owner = No_Symbol then
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Set_Pending_Discriminants
                      (Declaration_Targets, New_Id);
               if Ada.Strings.Fixed.Index (Decl_Lower, ")") /= 0 then
                  Add_Discriminant_Names (Analysis, Raw_Line, Line_Number, Depth + 1,
                                          New_Id);
                  Editor.Ada_Declaration_Parser.Parse_Line_Declaration_Phase
                    .Clear_Pending_Discriminants (Declaration_Targets);
               end if;
            elsif Kind = Symbol_Type
              and then Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
              and then not Has_Token (Decl_Lower, "record")
              and then not Has_Token (Decl_Lower, "array")
              and then not Has_Token (Decl_Lower, "range")
              and then not Has_Token (Decl_Lower, "access")
            then
               Add_Enumeration_Literals (Analysis, Raw_Line, Line_Number, Depth + 1,
                                         New_Id);
               if Ada.Strings.Fixed.Index (Decl_Lower, "(") /= 0
                 and then Ada.Strings.Fixed.Index (Decl_Lower, ")") = 0
               then
                  Editor.Ada_Declaration_Parser.Parse_Line_Executable_Phase
                    .Set_Pending_Enumeration (Executable_Binding, New_Id);
               end if;
            end if;
            if Has_Token (Decl_Lower, "is") and then not Has_Code_Char (Decl_Lower, ';')
           and then not Flags.Is_Instantiation and then not Flags.Is_Rename
           and then Kind /= Symbol_Type and then Kind /= Symbol_Subtype
           and then Kind /= Symbol_Generic_Formal_Subprogram
         then
               Editor.Ada_Declaration_Parser.Parse_Line_Scope_Phase
                 .Enter_Scope (Scope_State, New_Id);
            end if;
         end;
      end if;
   end Parse_Line;
