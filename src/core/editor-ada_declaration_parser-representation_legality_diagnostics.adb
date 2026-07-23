with Ada.Containers;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Attribute_Value_Helpers;
with Editor.Ada_Declaration_Parser.Freezing_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Target_Helpers;
with Editor.Ada_Language_Model;

package body Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics is

   use Editor.Ada_Language_Model;
   use type Ada.Containers.Count_Type;
   use type Freezing_Point_Kind;
   use type Legality_Diagnostic_Kind;
   use type Legality_Diagnostic_Severity;
   use type Representation_Clause_Kind;
   use type Scope_Id;
   use type Symbol_Id;
   use type Symbol_Kind;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Same_Text
     (Left, Right : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Same_Text;

   function Same_Local_Representation_Target
     (Current, Previous : Representation_Clause_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers
       .Same_Local_Representation_Target;

   function Ranges_Overlap
     (Left_First, Left_Last, Right_First, Right_Last : Natural) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Ranges_Overlap;

   function Global_First_Bit (Unit, First_Bit : Natural) return Natural
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Global_First_Bit;

   function Global_Last_Bit (Unit, Last_Bit : Natural) return Natural
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Global_Last_Bit;

   function Is_Local_Name_Start (C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Is_Local_Name_Start;

   function Is_Local_Name_Char (C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Is_Local_Name_Char;

   function Is_Type_Like_Target (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Type_Like_Target;

   function Is_Object_Like_Target (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Object_Like_Target;

   function Is_Access_Type_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Access_Type_Target;

   function Is_Storage_Size_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Storage_Size_Target;

   function Is_Array_Type_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Array_Type_Target;

   function Is_Fixed_Point_Type_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Fixed_Point_Type_Target;

   function Is_Floating_Point_Type_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Floating_Point_Type_Target;

   function Is_Atomic_Volatile_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Atomic_Volatile_Target;

   function Is_Suppress_Initialization_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Suppress_Initialization_Target;

   function Is_Unchecked_Union_Target (Info : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Unchecked_Union_Target;

   function Is_Subprogram_Like_Target (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Subprogram_Like_Target;

   function Is_Address_Clause_Target (Kind : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Address_Clause_Target;

   function Operational_Handler_Name (Text : String) return String
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Operational_Handler_Name;

   function Operational_Handler_Is_Compatible
     (Attribute_Name : Unbounded_String;
      Handler_Kind   : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Operational_Handler_Is_Compatible;

   function Is_Stream_Operational_Attribute
     (Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Stream_Operational_Attribute;

   function Is_Interfacing_Attribute
     (Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Interfacing_Attribute;

   function Is_Link_Name_Attribute
     (Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Link_Name_Attribute;

   function Is_Import_Export_Attribute
     (Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Import_Export_Attribute;

   function Is_Convention_Attribute
     (Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Convention_Attribute;

   function Is_Convention_Identifier (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Convention_Identifier;

   function Is_Static_Boolean_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_Boolean_Value;

   function Is_Static_True_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_True_Value;

   function Is_Known_Convention_Identifier (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Known_Convention_Identifier;

   function Is_Static_String_Literal (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_String_Literal;

   function Is_Raw_Numeric_Literal (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Raw_Numeric_Literal;

   function Is_Static_Numeric_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Static_Numeric_Value;

   function Is_Positive_Static_Natural_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Positive_Static_Natural_Value;

   function Is_Storage_Pool_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Storage_Pool_Value;

   function Is_Address_Null_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Null_Value;

   function Is_Address_Compatible_Expression (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Address_Compatible_Expression;

   function Is_Interfacing_Attribute_Target
     (Attribute_Name : Unbounded_String;
      Kind           : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Attribute_Value_Helpers.Is_Interfacing_Attribute_Target;

   function Is_Valid_Bit_Order_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Valid_Bit_Order_Value;

   function Is_Valid_Scalar_Storage_Order_Value (Text : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Valid_Scalar_Storage_Order_Value;

   function Is_Representation_Item_Subject_To_Freezing
     (Kind : Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Is_Representation_Item_Subject_To_Freezing;

   function Representation_Target_Is_Compatible
     (Clause : Representation_Clause_Info;
      Kind   : Symbol_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Representation_Target_Is_Compatible;

   function Requires_Static_Natural_Value
     (Kind : Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Declaration_Parser.Representation_Target_Helpers.Requires_Static_Natural_Value;

   function Has_Enabled_Import_Or_Export
     (Analysis : Analysis_Result;
      Target   : Symbol_Id) return Boolean is
   begin
      if Target = No_Symbol then
         return False;
      end if;

      for I in 1 .. Representation_Clause_Count (Analysis) loop
         declare
            Clause : constant Representation_Clause_Info :=
              Representation_Clause_At (Analysis, No_Symbol, I);
            A : constant String := Lower (To_String (Clause.Attribute_Name));
         begin
            if Clause.Target_Symbol = Target
              and then (A = "import" or else A = "export")
              and then Is_Static_True_Value (To_String (Clause.Item_Text))
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Has_Enabled_Import_Or_Export;

   function Last_Selected_Name_Part (Name : String) return String
     renames Editor.Ada_Declaration_Parser.Legality_Profile_Helpers.Last_Selected_Name_Part;

   function Find_Operational_Handler
     (Analysis : Analysis_Result;
      Name     : String) return Symbol_Id is
      Wanted : constant String := Normalize_Name (Last_Selected_Name_Part (Name));
   begin
      if Wanted = "" then
         return No_Symbol;
      end if;

      for I in reverse 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if To_String (S.Normalized_Name) = Wanted then
               return S.Id;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Find_Operational_Handler;

   function Find_Type_By_Name
     (Analysis : Analysis_Result;
      Name     : Unbounded_String) return Symbol_Id is
   begin
      return Editor.Ada_Declaration_Parser.Range_Structure_Helpers
        .Find_Type_By_Name (Analysis, Name);
   end Find_Type_By_Name;

   function Static_Size_For_Target
     (Analysis : Analysis_Result;
      Target   : Symbol_Id;
      Found    : out Boolean) return Natural is
   begin
      return Editor.Ada_Declaration_Parser.Range_Structure_Helpers
        .Static_Size_For_Target (Analysis, Target, Found);
   end Static_Size_For_Target;

   function Has_Enumeration_Representation_Association
     (Analysis : Analysis_Result;
      Target   : Symbol_Id;
      Literal_Name : Unbounded_String) return Boolean is
   begin
      for I in 1 .. Enumeration_Representation_Literal_Count (Analysis) loop
         declare
            Rep : constant Enumeration_Representation_Literal_Info :=
              Enumeration_Representation_Literal_At (Analysis, No_Symbol, I);
         begin
            if Rep.Target_Symbol = Target
              and then Lower (To_String (Rep.Literal_Name)) =
                To_String (Literal_Name)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Enumeration_Representation_Association;

   function Target_Has_Enumeration_Literals
     (Analysis : Analysis_Result;
      Target   : Symbol_Id) return Boolean is
   begin
      if Target = No_Symbol then
         return False;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Parent_Symbol = Target
              and then S.Kind = Symbol_Enumeration_Literal
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Target_Has_Enumeration_Literals;

   function Enumeration_Literal_Position
     (Analysis : Analysis_Result;
      Literal  : Symbol_Id) return Natural is
      Count  : Natural := 0;
      Target : Symbol_Id := No_Symbol;
   begin
      if Literal = No_Symbol
        or else Natural (Literal) > Natural (Symbol_Count (Analysis))
      then
         return 0;
      end if;

      Target := Symbol_At (Analysis, Positive (Literal)).Parent_Symbol;
      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Parent_Symbol = Target
              and then S.Kind = Symbol_Enumeration_Literal
            then
               Count := Count + 1;
               if S.Id = Literal then
                  return Count;
               end if;
            end if;
         end;
      end loop;

      return 0;
   end Enumeration_Literal_Position;

   procedure Note_Freezing_Point
     (Analysis : in out Analysis_Result;
      Target   : Symbol_Info;
      Trigger  : Symbol_Info;
      Kind     : Freezing_Point_Kind;
      Reason   : String) is
   begin
      Add_Freezing_Point
        (Analysis,
         Target.Id,
         Trigger.Id,
         Kind,
         Reason,
         Trigger.Source_Span);
   end Note_Freezing_Point;

   function Line_Before
     (Left  : Source_Range;
      Right : Source_Range) return Boolean
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Line_Before;

   function Text_Names_Target
     (Text : Unbounded_String;
      Name : Unbounded_String) return Boolean
     renames Editor.Ada_Declaration_Parser.Range_Structure_Helpers.Text_Names_Target;

   function Is_Freezable_Representation_Target
     (S : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Is_Freezable_Representation_Target;

   function Is_Targeted_Body_Completion
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Is_Targeted_Body_Completion;

   function Is_Generic_Formal_Freezing_Use
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Is_Generic_Formal_Freezing_Use;

   function Is_Symbol_Freezing_Use
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Is_Symbol_Freezing_Use;

   procedure Build_Freezing_Point_Index
     (Analysis : in out Analysis_Result) is
   begin
      for T in 1 .. Symbol_Count (Analysis) loop
         declare
            Target : constant Symbol_Info := Symbol_At (Analysis, T);
         begin
            if Is_Freezable_Representation_Target (Target) then
               for J in 1 .. Symbol_Count (Analysis) loop
                  declare
                     Trigger : constant Symbol_Info := Symbol_At (Analysis, J);
                  begin
                     if Trigger.Id /= Target.Id
                       and then Line_Before (Target.Source_Span, Trigger.Source_Span)
                     then
                        if Is_Targeted_Body_Completion (Target, Trigger) then
                           Note_Freezing_Point
                             (Analysis, Target, Trigger, Freezing_Body_Completion,
                              "body or completion freezes representation target");
                        elsif Trigger.Kind = Symbol_Instantiation
                          and then Is_Symbol_Freezing_Use (Target, Trigger)
                        then
                           Note_Freezing_Point
                             (Analysis, Target, Trigger, Freezing_Generic_Instance,
                              "generic instance freezes referenced target");
                        elsif Is_Generic_Formal_Freezing_Use (Target, Trigger) then
                           Note_Freezing_Point
                             (Analysis, Target, Trigger, Freezing_Generic_Formal_Use,
                              "generic formal declaration freezes referenced target");
                        elsif Is_Symbol_Freezing_Use (Target, Trigger) then
                           Note_Freezing_Point
                             (Analysis, Target, Trigger, Freezing_First_Use,
                              "declaration use freezes representation target");
                        end if;
                     end if;
                  end;
               end loop;

               for B_Index in 1 .. Executable_Binding_Count (Analysis) loop
                  declare
                     B : constant Executable_Binding_Info :=
                       Executable_Binding_At (Analysis, B_Index);
                  begin
                     if Line_Before (Target.Source_Span, B.Source_Span)
                       and then (Text_Names_Target (B.Name, Target.Normalized_Name)
                                 or else Text_Names_Target
                                   (B.Expression_Text, Target.Normalized_Name))
                     then
                        Add_Freezing_Point
                          (Analysis,
                           Target.Id,
                           No_Symbol,
                           Freezing_First_Use,
                           "executable use freezes representation target",
                           B.Source_Span);
                     end if;
                  end;
               end loop;

               for A_Index in 1 .. Generic_Actual_Count (Analysis) loop
                  declare
                     A : constant Generic_Actual_Info :=
                       Generic_Actual_At (Analysis, No_Symbol, A_Index);
                  begin
                     if To_String (A.Normalized_Actual_Name) =
                          To_String (Target.Normalized_Name)
                       and then Line_Before (Target.Source_Span, A.Source_Span)
                     then
                        Add_Freezing_Point
                          (Analysis,
                           Target.Id,
                           A.Instance_Symbol,
                           Freezing_Generic_Formal_Instance,
                           "generic actual association freezes representation target",
                           A.Source_Span);
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Build_Freezing_Point_Index;

   function Freezing_Message (Kind : Freezing_Point_Kind) return String
     renames Editor.Ada_Declaration_Parser.Freezing_Helpers.Freezing_Message;

   procedure Check_Representation_Freezing
     (Analysis : in out Analysis_Result;
      Clause   : Representation_Clause_Info) is
      Target : Symbol_Info;
   begin
      if Clause.Target_Symbol = No_Symbol
        or else Natural (Clause.Target_Symbol) > Symbol_Count (Analysis)
        or else not Is_Representation_Item_Subject_To_Freezing (Clause.Kind)
      then
         return;
      end if;

      Target := Symbol_At (Analysis, Positive (Clause.Target_Symbol));

      if Target.Flags.Is_Private then
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               Completion : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if Completion.Id /= Target.Id
                 and then Same_Text (Completion.Normalized_Name, Target.Normalized_Name)
                 and then Completion.Kind in Symbol_Type | Symbol_Record_Type
                 and then Line_Before (Clause.Source_Span, Completion.Source_Span)
               then
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Representation_Before_Completion,
                     "representation clause for private type " &
                       To_String (Clause.Target_Name) &
                       " appears before the retained full-type completion",
                     Legality_Error,
                     Target.Id,
                     Completion.Id,
                     Clause.Source_Span);
                  return;
               end if;
            end;
         end loop;
      end if;

      for FP_Index in 1 .. Freezing_Point_Count (Analysis, Target.Id) loop
         declare
            FP : constant Freezing_Point_Info :=
              Freezing_Point_At (Analysis, Target.Id, FP_Index);
         begin
            if Line_Before (Target.Source_Span, FP.Source_Span)
              and then Line_Before (FP.Source_Span, Clause.Source_Span)
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Representation_After_Freezing,
                  "representation clause for " & To_String (Clause.Target_Name) &
                    " appears after a " & Freezing_Message (FP.Kind),
                  Legality_Error,
                  Target.Id,
                  FP.Trigger_Symbol,
                  Clause.Source_Span);
               return;
            end if;
         end;
      end loop;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if S.Id /= Target.Id
              and then Line_Before (Target.Source_Span, S.Source_Span)
              and then Line_Before (S.Source_Span, Clause.Source_Span)
            then
               if Is_Targeted_Body_Completion (Target, S) then
                  Note_Freezing_Point
                    (Analysis, Target, S, Freezing_Body_Completion,
                     "body or completion before representation item");
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Representation_After_Freezing,
                     "representation clause for " & To_String (Clause.Target_Name) &
                       " appears after a body/completion freezing point",
                     Legality_Error,
                     Target.Id,
                     S.Id,
                     Clause.Source_Span);
                  return;
               elsif S.Kind = Symbol_Instantiation
                 and then Is_Symbol_Freezing_Use (Target, S)
               then
                  Note_Freezing_Point
                    (Analysis, Target, S, Freezing_Generic_Instance,
                     "generic instantiation before representation item");
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Representation_After_Freezing,
                     "representation clause for " & To_String (Clause.Target_Name) &
                       " appears after a generic instance freezing point",
                     Legality_Error,
                     Target.Id,
                     S.Id,
                     Clause.Source_Span);
                  return;
               elsif Is_Generic_Formal_Freezing_Use (Target, S) then
                  Note_Freezing_Point
                    (Analysis, Target, S, Freezing_Generic_Formal_Use,
                     "generic formal declaration before representation item");
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Representation_After_Freezing,
                     "representation clause for " & To_String (Clause.Target_Name) &
                       " appears after a generic formal freezing point",
                     Legality_Error,
                     Target.Id,
                     S.Id,
                     Clause.Source_Span);
                  return;
               elsif Text_Names_Target (S.Profile_Summary, Target.Normalized_Name)
                 or else Text_Names_Target (S.Target_Name, Target.Normalized_Name)
               then
                  Note_Freezing_Point
                    (Analysis, Target, S, Freezing_First_Use,
                     "declaration use before representation item");
                  Add_Legality_Diagnostic
                    (Analysis,
                     Legality_Representation_After_Freezing,
                     "representation clause for " & To_String (Clause.Target_Name) &
                       " appears after the target is frozen by an earlier use",
                     Legality_Error,
                     Target.Id,
                     S.Id,
                     Clause.Source_Span);
                  return;
               end if;
            end if;
         end;
      end loop;

      for I in 1 .. Executable_Binding_Count (Analysis) loop
         declare
            B : constant Executable_Binding_Info := Executable_Binding_At (Analysis, I);
         begin
            if Line_Before (Target.Source_Span, B.Source_Span)
              and then Line_Before (B.Source_Span, Clause.Source_Span)
              and then (Text_Names_Target (B.Name, Target.Normalized_Name)
                        or else Text_Names_Target (B.Expression_Text, Target.Normalized_Name))
            then
               Add_Freezing_Point
                 (Analysis,
                  Target.Id,
                  No_Symbol,
                  Freezing_First_Use,
                  "executable use before representation item",
                  B.Source_Span);
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Representation_After_Freezing,
                  "representation clause for " & To_String (Clause.Target_Name) &
                    " appears after an executable freezing use",
                  Legality_Error,
                  Target.Id,
                  No_Symbol,
                  Clause.Source_Span);
               return;
            end if;
         end;
      end loop;

      for I in 1 .. Generic_Actual_Count (Analysis) loop
         declare
            A : constant Generic_Actual_Info := Generic_Actual_At (Analysis, No_Symbol, I);
         begin
            if To_String (A.Normalized_Actual_Name) =
                 To_String (Target.Normalized_Name)
              and then Line_Before (Target.Source_Span, A.Source_Span)
              and then Line_Before (A.Source_Span, Clause.Source_Span)
            then
               Add_Freezing_Point
                 (Analysis,
                  Target.Id,
                  A.Instance_Symbol,
                  Freezing_Generic_Formal_Instance,
                  "generic actual association freezes the actual before representation item",
                  A.Source_Span);
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Representation_After_Freezing,
                  "representation clause for " & To_String (Clause.Target_Name) &
                    " appears after a generic actual/instance freezing point",
                  Legality_Error,
                  Target.Id,
                  A.Instance_Symbol,
                  Clause.Source_Span);
               return;
            end if;
         end;
      end loop;
   end Check_Representation_Freezing;

   procedure Add_Representation_Legality_Diagnostics
     (Analysis : in out Analysis_Result) is
      Storage_Unit_Bits : constant Natural := 8;

      function Find_Type_By_Name
        (Name : Unbounded_String) return Symbol_Id is
      begin
         return Editor.Ada_Declaration_Parser.Range_Structure_Helpers
           .Find_Type_By_Name (Analysis, Name);
      end Find_Type_By_Name;

      function Static_Size_For_Target
        (Target : Symbol_Id;
         Found  : out Boolean) return Natural is
      begin
         return Editor.Ada_Declaration_Parser.Range_Structure_Helpers
           .Static_Size_For_Target (Analysis, Target, Found);
      end Static_Size_For_Target;
   begin
      Build_Freezing_Point_Index (Analysis);

      --  Representation clauses: Ada permits at most one direct representation
      --  item for a given target/attribute kind.  Duplicates produce unstable
      --  editor metadata, so expose them as legality diagnostics.
      for I in 1 .. Representation_Clause_Count (Analysis) loop
         declare
            Current : constant Representation_Clause_Info :=
              Representation_Clause_At (Analysis, No_Symbol, I);
         begin
            Check_Representation_Freezing (Analysis, Current);

            if Current.Target_Symbol = No_Symbol then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Representation_Target_Not_Found,
                  "representation clause target " &
                    To_String (Current.Target_Name) & " was not resolved",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            else
               declare
                  Target_Info : constant Symbol_Info :=
                    Symbol_At (Analysis, Positive (Current.Target_Symbol));
               begin
                  if Current.Kind = Representation_Address_Clause
                    and then not Is_Address_Clause_Target (Target_Info.Kind)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Address_Target_Incompatible,
                        "Address representation clause requires an object, subprogram, or entry target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if not Representation_Target_Is_Compatible (Current, Target_Info.Kind) then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Representation_Target_Incompatible,
                        "representation clause kind is not valid for target " &
                          To_String (Current.Target_Name),
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Record_Mod_Clause
                    and then Target_Info.Kind /= Symbol_Record_Type
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Record_Mod_Target_Not_Record,
                        "record representation mod clause requires a record type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Enumeration_Clause
                    and then not Target_Has_Enumeration_Literals
                      (Analysis, Current.Target_Symbol)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Enumeration_Representation_Target_Not_Enumeration,
                        "enumeration representation clause requires an enumeration type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Storage_Pool_Clause |
                       Representation_Default_Storage_Pool_Clause
                    and then not Is_Access_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Storage_Pool_Target_Not_Access,
                        "Storage_Pool/Default_Storage_Pool representation clause requires an access type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Storage_Size_Clause
                    and then not Is_Storage_Size_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Storage_Size_Target_Incompatible,
                        "Storage_Size representation clause requires an access type or task type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Component_Size_Clause
                    and then not Is_Array_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Component_Size_Target_Not_Array,
                        "Component_Size representation clause requires an array type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Default_Component_Value_Clause
                    and then not Is_Array_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Representation_Target_Incompatible,
                        "Default_Component_Value representation property requires an array type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Integer_Literal_Clause |
                       Representation_Real_Literal_Clause |
                       Representation_String_Literal_Clause
                    and then not Is_Type_Like_Target (Target_Info.Kind)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Representation_Target_Incompatible,
                        "literal operational property requires a type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Designated_Storage_Model_Clause |
                       Representation_Storage_Model_Type_Clause
                    and then not Is_Access_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Representation_Target_Incompatible,
                        "storage-model operational property requires an access type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Object_Size_Clause |
                       Representation_Value_Size_Clause
                    and then not (Is_Type_Like_Target (Target_Info.Kind)
                                  or else Is_Object_Like_Target (Target_Info.Kind))
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Object_Value_Size_Target_Incompatible,
                        "Object_Size/Value_Size representation clause requires a type or object target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Scalar_Storage_Order_Clause
                    and then not Is_Type_Like_Target (Target_Info.Kind)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Scalar_Storage_Order_Target_Incompatible,
                        "Scalar_Storage_Order representation clause requires a type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Small_Clause
                    and then not Is_Fixed_Point_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Small_Target_Not_Fixed_Point,
                        "Small representation clause requires a fixed-point type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Machine_Radix_Clause
                    and then not Is_Floating_Point_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Machine_Radix_Target_Not_Floating_Point,
                        "Machine_Radix representation clause requires a floating-point type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Aft_Clause
                    and then not Is_Fixed_Point_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Aft_Target_Not_Fixed_Point,
                        "Aft representation clause requires a fixed-point type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Atomic_Clause |
                       Representation_Volatile_Clause |
                       Representation_Independent_Clause
                    and then not Is_Atomic_Volatile_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Atomic_Volatile_Target_Incompatible,
                        "Atomic/Volatile/Independent representation clause requires a type or object target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind in Representation_Atomic_Components_Clause |
                       Representation_Volatile_Components_Clause |
                       Representation_Independent_Components_Clause
                    and then not Is_Array_Type_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Atomic_Volatile_Target_Incompatible,
                        "Atomic_Components/Volatile_Components/Independent_Components representation clause requires an array type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Unchecked_Union_Clause
                    and then not Is_Unchecked_Union_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Unchecked_Union_Target_Incompatible,
                        "Unchecked_Union representation clause requires a record type target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Current.Kind = Representation_Suppress_Initialization_Clause
                    and then not Is_Suppress_Initialization_Target (Target_Info)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Suppress_Initialization_Target_Incompatible,
                        "Suppress_Initialization representation clause requires a type or object target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Interfacing_Attribute (Current.Attribute_Name)
                    and then not Is_Interfacing_Attribute_Target
                      (Current.Attribute_Name, Target_Info.Kind)
                  then
                     if Is_Link_Name_Attribute (Current.Attribute_Name) then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Interfacing_Link_Name_Target_Incompatible,
                           "interfacing representation attribute " &
                             To_String (Current.Attribute_Name) &
                             " is not valid for target " &
                             To_String (Current.Target_Name),
                           Legality_Error,
                           Current.Target_Symbol,
                           No_Symbol,
                           Current.Source_Span);
                     else
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Interfacing_Attribute_Target_Incompatible,
                           "interfacing representation attribute " &
                             To_String (Current.Attribute_Name) &
                             " is not valid for target " &
                             To_String (Current.Target_Name),
                           Legality_Error,
                           Current.Target_Symbol,
                           No_Symbol,
                           Current.Source_Span);
                     end if;
                  end if;

                  if Is_Link_Name_Attribute (Current.Attribute_Name)
                    and then not Is_Static_String_Literal (To_String (Current.Item_Text))
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Interfacing_String_Value_Required,
                        "interfacing attribute " &
                          To_String (Current.Attribute_Name) &
                          " requires a static string literal value",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Convention_Attribute (Current.Attribute_Name)
                    and then not Is_Convention_Identifier (To_String (Current.Item_Text))
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Convention_Identifier_Required,
                        "Convention representation attribute requires a convention identifier value",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Import_Export_Attribute (Current.Attribute_Name)
                    and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Import_Export_Boolean_Value_Required,
                        "Import/Export representation attribute requires a static Boolean value",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Convention_Attribute (Current.Attribute_Name)
                    and then Is_Convention_Identifier (To_String (Current.Item_Text))
                    and then not Is_Known_Convention_Identifier
                      (To_String (Current.Item_Text))
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Convention_Identifier_Unknown,
                        "Convention representation attribute uses an unknown convention identifier",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Link_Name_Attribute (Current.Attribute_Name)
                    and then not Has_Enabled_Import_Or_Export (Analysis, Current.Target_Symbol)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Interfacing_Link_Name_Requires_Import_Export,
                        "External_Name/Link_Name requires an enabled Import or Export clause for the same target",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;

                  if Is_Import_Export_Attribute (Current.Attribute_Name)
                    and then Is_Static_True_Value (To_String (Current.Item_Text))
                  then
                     for J in 1 .. Representation_Clause_Count (Analysis) loop
                        declare
                           Other : constant Representation_Clause_Info :=
                             Representation_Clause_At (Analysis, No_Symbol, J);
                        begin
                           if Other.Target_Symbol = Current.Target_Symbol
                             and then Other.Target_Symbol /= No_Symbol
                             and then Lower (To_String (Other.Attribute_Name)) /=
                               Lower (To_String (Current.Attribute_Name))
                             and then Is_Import_Export_Attribute
                               (Other.Attribute_Name)
                             and then Is_Static_True_Value
                               (To_String (Other.Item_Text))
                           then
                              Add_Legality_Diagnostic
                                (Analysis,
                                 Legality_Interfacing_Import_Export_Conflict,
                                 "Import and Export cannot both be enabled for the same representation target",
                                 Legality_Error,
                                 Current.Target_Symbol,
                                 Other.Target_Symbol,
                                 Current.Source_Span);
                              exit;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end if;

            if Requires_Static_Natural_Value (Current.Kind)
              and then not Current.Has_Static_Value
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  (if Current.Kind = Representation_Record_Mod_Clause
                   then Legality_Record_Mod_Static_Value_Required
                   else Legality_Representation_Static_Value_Required),
                  (if Current.Kind = Representation_Record_Mod_Clause
                   then "record representation mod clause requires a static natural value"
                   else "representation attribute for " &
                     To_String (Current.Target_Name) &
                     " requires a static natural value"),
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Bit_Order_Clause
              and then not Is_Valid_Bit_Order_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Bit_Order_Invalid_Value,
                  "Bit_Order representation clause must use Low_Order_First or High_Order_First",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_Scalar_Storage_Order_Clause |
                 Representation_Default_Scalar_Storage_Order_Clause
              and then not Is_Valid_Scalar_Storage_Order_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Scalar_Storage_Order_Invalid_Value,
                  "Scalar_Storage_Order representation clause must use Low_Order_First or High_Order_First",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Pack_Clause
              and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Pack_Boolean_Value_Required,
                  "Pack representation clause requires a static Boolean value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_Atomic_Clause |
                 Representation_Volatile_Clause |
                 Representation_Independent_Clause |
                 Representation_Atomic_Components_Clause |
                 Representation_Volatile_Components_Clause |
                 Representation_Independent_Components_Clause
              and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Atomic_Volatile_Boolean_Value_Required,
                  "Atomic/Volatile/Independent representation clause requires a static Boolean value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Unchecked_Union_Clause
              and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Unchecked_Union_Boolean_Value_Required,
                  "Unchecked_Union representation clause requires a static Boolean value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Suppress_Initialization_Clause
              and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Suppress_Initialization_Boolean_Value_Required,
                  "Suppress_Initialization representation clause requires a static Boolean value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_No_Controlled_Parts_Clause |
                 Representation_Preelaborable_Initialization_Clause |
                 Representation_No_Task_Parts_Clause |
                 Representation_Exclusive_Functions_Clause |
                 Representation_Simple_Storage_Pool_Type_Clause |
                 Representation_Discard_Names_Clause |
                 Representation_Volatile_Function_Clause |
                 Representation_Interrupt_Handler_Clause |
                 Representation_Async_Readers_Clause |
                 Representation_Async_Writers_Clause |
                 Representation_Effective_Reads_Clause |
                 Representation_Effective_Writes_Clause |
                 Representation_Ghost_Clause |
                 Representation_Relaxed_Initialization_Clause |
                 Representation_Nonblocking_Clause |
                 Representation_Nonblocking_Class_Clause |
                 Representation_Always_Terminates_Clause |
                 Representation_Inline_Clause |
                 Representation_Inline_Always_Clause |
                 Representation_No_Return_Clause |
                 Representation_Elaborate_Body_Clause |
                 Representation_Preelaborate_Clause |
                 Representation_Pure_Clause |
                 Representation_Remote_Types_Clause |
                 Representation_Remote_Call_Interface_Clause |
                 Representation_All_Calls_Remote_Clause |
                 Representation_No_Tagged_Streams_Clause |
                 Representation_Extensions_Visible_Clause |
                 Representation_Remote_Access_Type_Clause |
                 Representation_Shared_Passive_Clause |
                 Representation_Side_Effects_Clause |
                 Representation_No_Caching_Clause |
                 Representation_Warnings_Clause |
                 Representation_Weak_External_Clause |
                 Representation_Unreferenced_Clause |
                 Representation_Unmodified_Clause |
                 Representation_No_Elaboration_Code_Clause |
                 Representation_Persistent_BSS_Clause |
                 Representation_Universal_Aliasing_Clause |
                 Representation_Volatile_Full_Access_Clause |
                 Representation_Atomic_Always_Lock_Free_Clause |
                 Representation_No_Inline_Clause |
                 Representation_No_Strict_Aliasing_Clause |
                 Representation_Obsolescent_Clause |
                 Representation_Reviewable_Clause
              and then not Is_Static_Boolean_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Pack_Boolean_Value_Required,
                  "Boolean representation/operational property requires a static Boolean value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Small_Clause
              and then not Is_Static_Numeric_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Small_Static_Value_Required,
                  "Small representation clause requires a static numeric value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_Alignment_Clause |
                 Representation_Record_Mod_Clause |
                 Representation_Component_Size_Clause |
                 Representation_Object_Size_Clause |
                 Representation_Value_Size_Clause |
                 Representation_Storage_Size_Clause |
                 Representation_Stream_Size_Clause |
                 Representation_Max_Entry_Queue_Length_Clause |
                 Representation_CPU_Clause |
                 Representation_Max_Size_In_Storage_Elements_Clause |
                 Representation_Machine_Radix_Clause |
                 Representation_Aft_Clause
              and then Current.Has_Static_Value
              and then Current.Static_Value = 0
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  (if Current.Kind = Representation_Record_Mod_Clause
                   then Legality_Record_Mod_Positive_Value_Required
                   else Legality_Representation_Positive_Value_Required),
                  (if Current.Kind = Representation_Record_Mod_Clause
                   then "record representation mod clause requires a positive static value"
                   else "representation attribute requires a positive static value"),
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_Storage_Pool_Clause |
                 Representation_Default_Storage_Pool_Clause
              and then not Is_Storage_Pool_Value (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Storage_Pool_Value_Incompatible,
                  "Storage_Pool/Default_Storage_Pool representation clause requires a storage-pool object expression",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_External_Tag_Clause
              and then not Is_Static_String_Literal (To_String (Current.Item_Text))
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Interfacing_String_Value_Required,
                  "External_Tag representation attribute requires a static string literal value",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind in Representation_Integer_Literal_Clause |
                 Representation_Real_Literal_Clause |
                 Representation_String_Literal_Clause |
                 Representation_Storage_Model_Type_Clause |
                 Representation_Designated_Storage_Model_Clause |
                 Representation_Stable_Properties_Clause |
                 Representation_Stable_Properties_Class_Clause |
                 Representation_Predicate_Clause |
                 Representation_Static_Predicate_Clause |
                 Representation_Dynamic_Predicate_Clause |
                 Representation_Predicate_Failure_Clause |
                 Representation_Invariant_Clause |
                 Representation_Type_Invariant_Clause |
                 Representation_Type_Invariant_Class_Clause |
                 Representation_Initial_Condition_Clause |
                 Representation_Default_Initial_Condition_Clause |
                 Representation_Pre_Clause |
                 Representation_Pre_Class_Clause |
                 Representation_Precondition_Clause |
                 Representation_Post_Clause |
                 Representation_Post_Class_Clause |
                 Representation_Postcondition_Clause |
                 Representation_Refined_Post_Clause |
                 Representation_Global_Clause |
                 Representation_Depends_Clause |
                 Representation_Refined_Global_Clause |
                 Representation_Refined_Depends_Clause |
                 Representation_Abstract_State_Clause |
                 Representation_Refined_State_Clause |
                 Representation_Initializes_Clause |
                 Representation_Part_Of_Clause |
                 Representation_Relative_Deadline_Clause |
                 Representation_Contract_Cases_Clause |
                 Representation_Subprogram_Variant_Clause |
                 Representation_Exceptional_Cases_Clause |
                 Representation_SPARK_Mode_Clause |
                 Representation_Test_Case_Clause |
                 Representation_Annotate_Clause |
                 Representation_Linker_Section_Clause |
                 Representation_Machine_Attribute_Clause |
                 Representation_Optimize_Clause |
                 Representation_Suppress_Clause |
                 Representation_Unsuppress_Clause |
                 Representation_Assertion_Policy_Clause |
                 Representation_Check_Policy_Clause |
                 Representation_Debug_Policy_Clause |
                 Representation_Restrictions_Clause |
                 Representation_Restriction_Warnings_Clause |
                 Representation_Profile_Clause |
                 Representation_Dimension_System_Clause |
                 Representation_Dimension_Clause
              and then Trim (To_String (Current.Item_Text)) = ""
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Representation_Static_Value_Required,
                  "operational property requires a specified handler or model expression",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Kind = Representation_Address_Clause then
               declare
                  Address_Text : constant String := Trim (To_String (Current.Item_Text));
               begin
                  if Address_Text = "" then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Address_Value_Required,
                        "Address representation clause requires an address expression",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  elsif Is_Address_Null_Value (Address_Text) then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Address_Value_Null_Not_Allowed,
                        "Address representation clause cannot use the null literal",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  elsif Is_Static_String_Literal (Address_Text)
                    or else Is_Static_Boolean_Value (Address_Text)
                    or else Is_Raw_Numeric_Literal (Address_Text)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Address_Value_Incompatible,
                        "Address representation clause value must be a System.Address expression",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  elsif not Is_Address_Compatible_Expression (Address_Text) then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Address_Value_Not_Static_Address,
                        "Address representation clause value is not a retained static address expression",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  end if;
               end;
            end if;

            if Is_Stream_Operational_Attribute (Current.Attribute_Name) then
               declare
                  Handler_Name : constant String :=
                    Operational_Handler_Name (To_String (Current.Item_Text));
                  Handler      : constant Symbol_Id :=
                    Find_Operational_Handler (Analysis, Handler_Name);
               begin
                  if Handler_Name = "" or else Handler = No_Symbol then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Operational_Attribute_Handler_Not_Found,
                        "operational attribute " &
                          To_String (Current.Attribute_Name) &
                          " for " & To_String (Current.Target_Name) &
                          " does not name a retained handler",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  else
                     declare
                        Handler_Info : constant Symbol_Info :=
                          Symbol_At (Analysis, Positive (Handler));
                     begin
                        if not Operational_Handler_Is_Compatible
                          (Current.Attribute_Name, Handler_Info.Kind)
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Operational_Attribute_Handler_Incompatible,
                              "operational attribute " &
                                To_String (Current.Attribute_Name) &
                                " for " & To_String (Current.Target_Name) &
                                " names an incompatible handler",
                              Legality_Error,
                              Current.Target_Symbol,
                              Handler,
                              Current.Source_Span);
                        elsif not Editor.Ada_Declaration_Parser.Legality_Profile_Helpers
                          .Stream_Handler_Profile_Is_Compatible
                          (Current.Attribute_Name,
                           To_String (Current.Target_Name),
                           To_String (Handler_Info.Profile_Summary))
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Stream_Attribute_Profile_Incompatible,
                              "stream operational attribute " &
                                To_String (Current.Attribute_Name) &
                                " for " & To_String (Current.Target_Name) &
                                " names a handler with an incompatible profile",
                              Legality_Error,
                              Current.Target_Symbol,
                              Handler,
                              Current.Source_Span);
                        elsif not Editor.Ada_Declaration_Parser.Legality_Profile_Helpers
                          .Stream_Handler_Mode_Is_Compatible
                          (Current.Attribute_Name,
                           To_String (Handler_Info.Profile_Summary))
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Stream_Attribute_Mode_Incompatible,
                              "stream operational attribute " &
                                To_String (Current.Attribute_Name) &
                                " for " & To_String (Current.Target_Name) &
                                " names a handler with incompatible item parameter mode",
                              Legality_Error,
                              Current.Target_Symbol,
                              Handler,
                              Current.Source_Span);
                        end if;
                     end;
                  end if;
               end;
            end if;

            if Current.Kind = Representation_Put_Image_Clause then
               declare
                  Handler_Name : constant String :=
                    Operational_Handler_Name (To_String (Current.Item_Text));
                  Handler      : constant Symbol_Id :=
                    Find_Operational_Handler (Analysis, Handler_Name);
               begin
                  if Handler_Name = "" or else Handler = No_Symbol then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Operational_Attribute_Handler_Not_Found,
                        "operational attribute Put_Image for " &
                          To_String (Current.Target_Name) &
                          " does not name a retained handler",
                        Legality_Error,
                        Current.Target_Symbol,
                        No_Symbol,
                        Current.Source_Span);
                  else
                     declare
                        Handler_Info : constant Symbol_Info :=
                          Symbol_At (Analysis, Positive (Handler));
                     begin
                        if not Operational_Handler_Is_Compatible
                          (Current.Attribute_Name, Handler_Info.Kind)
                        then
                           Add_Legality_Diagnostic
                             (Analysis,
                              Legality_Operational_Attribute_Handler_Incompatible,
                              "operational attribute Put_Image for " &
                                To_String (Current.Target_Name) &
                                " names an incompatible handler",
                              Legality_Error,
                              Current.Target_Symbol,
                              Handler,
                              Current.Source_Span);
                        end if;
                     end;
                  end if;
               end;
            end if;

            for J in 1 .. I - 1 loop
               declare
                  Previous : constant Representation_Clause_Info :=
                    Representation_Clause_At (Analysis, No_Symbol, J);
               begin
                  if Current.Kind = Previous.Kind
                    and then Same_Local_Representation_Target (Current, Previous)
                    and then Same_Text (Current.Attribute_Name,
                                        Previous.Attribute_Name)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Duplicate_Representation_Clause,
                        "duplicate representation clause for " &
                          To_String (Current.Target_Name),
                        Legality_Error,
                        Current.Target_Symbol,
                        Previous.Target_Symbol,
                        Current.Source_Span);
                     exit;
                  end if;
               end;
            end loop;
         end;
      end loop;

      --  Enumeration representation clauses must cover retained literals of
      --  their target enumeration type.
      for I in 1 .. Representation_Clause_Count (Analysis) loop
         declare
            Current : constant Representation_Clause_Info :=
              Representation_Clause_At (Analysis, No_Symbol, I);
         begin
            if Current.Kind = Representation_Enumeration_Clause
              and then Current.Target_Symbol /= No_Symbol
            then
               for J in 1 .. Symbol_Count (Analysis) loop
                  declare
                     Lit : constant Symbol_Info := Symbol_At (Analysis, J);
                  begin
                     if Lit.Kind = Symbol_Enumeration_Literal
                       and then Lit.Parent_Symbol = Current.Target_Symbol
                       and then not Has_Enumeration_Representation_Association
                         (Analysis, Current.Target_Symbol, Lit.Normalized_Name)
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Enumeration_Representation_Missing_Literal,
                           "enumeration representation clause for " &
                             To_String (Current.Target_Name) &
                             " does not cover literal " & To_String (Lit.Name),
                           Legality_Error,
                           Current.Target_Symbol,
                           Lit.Id,
                           Current.Source_Span);
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      for I in 1 .. Enumeration_Representation_Literal_Count (Analysis) loop
         declare
            Current : constant Enumeration_Representation_Literal_Info :=
              Enumeration_Representation_Literal_At (Analysis, No_Symbol, I);
         begin
            if Current.Literal_Symbol = No_Symbol then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Enumeration_Representation_Literal_Not_Found,
                  "enumeration representation literal " &
                    To_String (Current.Literal_Name) &
                    " was not found in the target type",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            for J in 1 .. I - 1 loop
               declare
                  Previous : constant Enumeration_Representation_Literal_Info :=
                    Enumeration_Representation_Literal_At (Analysis, No_Symbol, J);
               begin
                  if Previous.Target_Symbol = Current.Target_Symbol
                    and then Same_Text (Current.Literal_Name, Previous.Literal_Name)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Duplicate_Enumeration_Representation_Literal,
                        "duplicate enumeration representation literal " &
                          To_String (Current.Literal_Name),
                        Legality_Error,
                        Current.Literal_Symbol,
                        Previous.Literal_Symbol,
                        Current.Source_Span);
                     exit;
                  end if;
               end;
            end loop;

            if not Current.Has_Static_Value then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Enumeration_Representation_Static_Value_Required,
                  "enumeration representation value for " &
                    To_String (Current.Literal_Name) &
                    " must be a static integer expression",
                  Legality_Error,
                  Current.Target_Symbol,
                  Current.Literal_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Has_Static_Value then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Enumeration_Representation_Literal_Info :=
                       Enumeration_Representation_Literal_At (Analysis, No_Symbol, J);
                  begin
                     if Previous.Has_Static_Value
                       and then Previous.Target_Symbol = Current.Target_Symbol
                       and then Previous.Static_Value = Current.Static_Value
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Duplicate_Enumeration_Representation_Value,
                           "duplicate enumeration representation value " &
                             Natural'Image (Current.Static_Value) & " for " &
                             To_String (Current.Literal_Name),
                           Legality_Error,
                           Current.Literal_Symbol,
                           Previous.Literal_Symbol,
                           Current.Source_Span);
                        exit;
                     elsif Previous.Has_Static_Value
                       and then Previous.Target_Symbol = Current.Target_Symbol
                       and then Previous.Literal_Symbol /= No_Symbol
                       and then Current.Literal_Symbol /= No_Symbol
                       and then Enumeration_Literal_Position
                         (Analysis, Previous.Literal_Symbol) <
                         Enumeration_Literal_Position (Analysis, Current.Literal_Symbol)
                       and then Previous.Static_Value >= Current.Static_Value
                     then
                        Add_Legality_Diagnostic
                          (Analysis,
                           Legality_Enumeration_Representation_Order_Mismatch,
                           "enumeration representation values must preserve literal order",
                           Legality_Error,
                           Current.Literal_Symbol,
                           Previous.Literal_Symbol,
                           Current.Source_Span);
                        exit;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      --  Record representation component clauses require a non-empty bit range
      --  and non-overlapping bit intervals for components placed at the same
      --  static storage unit.
      for I in 1 .. Representation_Component_Count (Analysis) loop
         declare
            Current : constant Representation_Component_Info :=
              Representation_Component_At (Analysis, No_Symbol, I);
         begin
            if Current.Target_Symbol /= No_Symbol then
               declare
                  Target_Info : constant Symbol_Info :=
                    Symbol_At (Analysis, Positive (Current.Target_Symbol));
               begin
                  if Target_Info.Kind /= Symbol_Record_Type then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Record_Component_Target_Not_Record,
                        "record representation component clause belongs to a non-record target",
                        Legality_Error,
                        Current.Target_Symbol,
                        Current.Component_Symbol,
                        Current.Source_Span);
                  end if;
               end;
            end if;

            if Current.Component_Symbol = No_Symbol then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Record_Component_Not_Found,
                  "record representation component " &
                    To_String (Current.Component_Name) &
                    " was not found in the target record type",
                  Legality_Error,
                  Current.Target_Symbol,
                  No_Symbol,
                  Current.Source_Span);
            end if;

            for J in 1 .. I - 1 loop
               declare
                  Previous : constant Representation_Component_Info :=
                    Representation_Component_At (Analysis, No_Symbol, J);
               begin
                  if Previous.Target_Symbol = Current.Target_Symbol
                    and then Same_Text (Current.Component_Name, Previous.Component_Name)
                  then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Duplicate_Record_Component_Representation,
                        "duplicate record representation component clause for " &
                          To_String (Current.Component_Name),
                        Legality_Error,
                        Current.Component_Symbol,
                        Previous.Component_Symbol,
                        Current.Source_Span);
                     exit;
                  end if;
               end;
            end loop;

            if not Current.Has_Static_Storage_Unit then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Record_Component_Static_Position_Required,
                  "record representation component " &
                    To_String (Current.Component_Name) &
                    " requires a static storage position",
                  Legality_Error,
                  Current.Component_Symbol,
                  Current.Target_Symbol,
                  Current.Source_Span);
            end if;

            if not Current.Has_Static_First_Bit
              or else not Current.Has_Static_Last_Bit
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Record_Component_Static_Bit_Range_Required,
                  "record representation component " &
                    To_String (Current.Component_Name) &
                    " requires static first and last bit values",
                  Legality_Error,
                  Current.Component_Symbol,
                  Current.Target_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Has_Static_First_Bit
              and then Current.Has_Static_Last_Bit
              and then Current.Static_First_Bit > Current.Static_Last_Bit
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Record_Component_Invalid_Bit_Range,
                  "record representation component " &
                    To_String (Current.Component_Name) &
                    " has first bit after last bit",
                  Legality_Error,
                  Current.Component_Symbol,
                  Current.Target_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Has_Static_First_Bit
              and then Current.Has_Static_Last_Bit
              and then Current.Static_First_Bit <= Current.Static_Last_Bit
              and then (Current.Static_First_Bit >= Storage_Unit_Bits
                        or else Current.Static_Last_Bit >= Storage_Unit_Bits)
            then
               Add_Legality_Diagnostic
                 (Analysis,
                  Legality_Record_Component_Bit_Out_Of_Storage_Unit,
                  "record representation component " &
                    To_String (Current.Component_Name) &
                    " uses bit numbers outside the retained storage-unit model",
                  Legality_Error,
                  Current.Component_Symbol,
                  Current.Target_Symbol,
                  Current.Source_Span);
            end if;

            if Current.Component_Symbol /= No_Symbol
              and then Current.Has_Static_First_Bit
              and then Current.Has_Static_Last_Bit
              and then Current.Static_First_Bit <= Current.Static_Last_Bit
            then
               declare
                  Component_Info : constant Symbol_Info :=
                    Symbol_At (Analysis, Positive (Current.Component_Symbol));
                  Component_Type : constant Symbol_Id :=
                    Find_Type_By_Name (Component_Info.Target_Name);
                  Found_Size : Boolean := False;
                  Needed_Size : constant Natural :=
                    Static_Size_For_Target (Component_Type, Found_Size);
                  Clause_Size : constant Natural :=
                    Current.Static_Last_Bit - Current.Static_First_Bit + 1;
               begin
                  if Found_Size and then Clause_Size < Needed_Size then
                     Add_Legality_Diagnostic
                       (Analysis,
                        Legality_Record_Component_Size_Too_Small,
                        "record representation component " &
                          To_String (Current.Component_Name) &
                          " reserves fewer bits than the retained component subtype size",
                        Legality_Error,
                        Current.Component_Symbol,
                        Component_Type,
                        Current.Source_Span);
                  end if;
               end;
            end if;

            if Current.Has_Static_Storage_Unit
              and then Current.Has_Static_First_Bit
              and then Current.Has_Static_Last_Bit
              and then Current.Static_First_Bit <= Current.Static_Last_Bit
            then
               for J in 1 .. I - 1 loop
                  declare
                     Previous : constant Representation_Component_Info :=
                       Representation_Component_At (Analysis, No_Symbol, J);
                  begin
                     if Previous.Target_Symbol = Current.Target_Symbol
                       and then Previous.Has_Static_Storage_Unit
                       and then Previous.Has_Static_First_Bit
                       and then Previous.Has_Static_Last_Bit
                       and then Previous.Static_First_Bit <= Previous.Static_Last_Bit
                     then
                        declare
                           Previous_First : constant Natural :=
                             Global_First_Bit
                               (Previous.Static_Storage_Unit,
                                Previous.Static_First_Bit);
                           Previous_Last : constant Natural :=
                             Global_Last_Bit
                               (Previous.Static_Storage_Unit,
                                Previous.Static_Last_Bit);
                           Current_First : constant Natural :=
                             Global_First_Bit
                               (Current.Static_Storage_Unit,
                                Current.Static_First_Bit);
                           Current_Last : constant Natural :=
                             Global_Last_Bit
                               (Current.Static_Storage_Unit,
                                Current.Static_Last_Bit);
                        begin
                           if Ranges_Overlap
                             (Previous_First, Previous_Last,
                              Current_First, Current_Last)
                           then
                              Add_Legality_Diagnostic
                                (Analysis,
                                 (if Previous.Static_Storage_Unit = Current.Static_Storage_Unit
                                  then Legality_Record_Component_Overlap
                                  else Legality_Record_Component_Cross_Storage_Overlap),
                                 "record representation component " &
                                   To_String (Current.Component_Name) &
                                   " overlaps " & To_String (Previous.Component_Name),
                                 Legality_Error,
                                 Current.Component_Symbol,
                                 Previous.Component_Symbol,
                                 Current.Source_Span);
                              exit;
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Add_Representation_Legality_Diagnostics;

end Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics;
