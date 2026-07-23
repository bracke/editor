with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Target_Helpers;

package body Editor.Ada_Declaration_Parser.Freezing_Helpers is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
   use Editor.Ada_Declaration_Parser.Representation_Target_Helpers;
   use Editor.Ada_Language_Model;

   function Line_Before
     (Left  : Source_Range;
      Right : Source_Range) return Boolean is
   begin
      return Left.Start_Line < Right.Start_Line
        or else (Left.Start_Line = Right.Start_Line
                 and then Left.Start_Column < Right.Start_Column);
   end Line_Before;

   function Is_Freezable_Representation_Target (S : Symbol_Info) return Boolean is
   begin
      return To_String (S.Normalized_Name) /= ""
        and then S.Kind in Symbol_Package | Symbol_Package_Body |
          Symbol_Procedure | Symbol_Function | Symbol_Operator_Function |
          Symbol_Type | Symbol_Subtype | Symbol_Record_Type |
          Symbol_Object | Symbol_Constant | Symbol_Task | Symbol_Protected |
          Symbol_Entry | Symbol_Generic_Package | Symbol_Generic_Subprogram |
          Symbol_Instantiation;
   end Is_Freezable_Representation_Target;

   function Is_Targeted_Body_Completion
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
   is
   begin
      if not (Trigger.Kind in Symbol_Package_Body | Symbol_Separate_Body
              or else Trigger.Flags.Is_Body)
      then
         return False;
      end if;

      return To_String (Trigger.Normalized_Name) = To_String (Target.Normalized_Name)
        or else Text_Names_Target (Trigger.Target_Name, Target.Normalized_Name)
        or else Text_Names_Target (Trigger.Profile_Summary, Target.Normalized_Name);
   end Is_Targeted_Body_Completion;

   function Is_Generic_Formal_Freezing_Use
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
   is
   begin
      if Trigger.Id = Target.Id
        or else To_String (Target.Normalized_Name) = ""
      then
         return False;
      end if;

      if Trigger.Kind not in Symbol_Generic_Formal_Object |
        Symbol_Generic_Formal_Subprogram | Symbol_Generic_Formal_Package
      then
         return False;
      end if;

      return Text_Names_Target (Trigger.Profile_Summary, Target.Normalized_Name)
        or else Text_Names_Target (Trigger.Target_Name, Target.Normalized_Name);
   end Is_Generic_Formal_Freezing_Use;

   function Is_Symbol_Freezing_Use
     (Target  : Symbol_Info;
      Trigger : Symbol_Info) return Boolean
   is
   begin
      if Trigger.Id = Target.Id
        or else To_String (Target.Normalized_Name) = ""
      then
         return False;
      end if;

      if Trigger.Kind in Symbol_Enumeration_Literal | Symbol_Record_Component |
        Symbol_Discriminant | Symbol_Generic_Formal_Type |
        Symbol_Generic_Formal_Object | Symbol_Generic_Formal_Subprogram |
        Symbol_Generic_Formal_Package
      then
         return False;
      end if;

      return Text_Names_Target (Trigger.Profile_Summary, Target.Normalized_Name)
        or else Text_Names_Target (Trigger.Target_Name, Target.Normalized_Name);
   end Is_Symbol_Freezing_Use;

   function Freezing_Message (Kind : Freezing_Point_Kind) return String is
   begin
      case Kind is
         when Freezing_Body_Completion =>
            return "body/completion freezing point";
         when Freezing_Generic_Instance =>
            return "generic instance freezing point";
         when Freezing_Generic_Formal_Use =>
            return "generic formal freezing point";
         when Freezing_Generic_Formal_Instance =>
            return "generic actual/instance freezing point";
         when Freezing_First_Use =>
            return "earlier freezing use";
      end case;
   end Freezing_Message;

end Editor.Ada_Declaration_Parser.Freezing_Helpers;
