with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Image_Helpers;
with Editor.Commands;
with Editor.Commands.Workflow_Messages;

package body Editor.Feature_Diagnostics.Labels is

   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Severity_Label (Severity : Diagnostic_Severity) return String is
   begin
      case Severity is
         when Diagnostic_Info    => return "info";
         when Diagnostic_Note    => return "note";
         when Diagnostic_Warning => return "warning";
         when Diagnostic_Error   => return "error";
         when Diagnostic_Unknown => return "unknown";
      end case;
   end Severity_Label;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source   => return "editor";
         when File_Diagnostic_Source     => return "file";
         when Project_Diagnostic_Source  => return "project";
         when External_Diagnostic_Source => return "external";
         when Unknown_Diagnostic_Source  => return "unknown";
      end case;
   end Source_Kind_Label;

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String
   is
   begin
      return Severity_Label (Severity);
   end Severity_Label_For_Display;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return Source_Kind_Label (Source_Kind);
   end Source_Kind_Label_For_Display;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean is
   begin
      return Item.Is_Build_Produced;
   end Is_Build_Produced_Item;

   function Producer_Label (Item : Diagnostic_Item) return String is
   begin
      if Is_Build_Produced_Item (Item) then
         return "Build";
      end if;

      case Item.Source_Kind is
         when Editor_Diagnostic_Source   => return "Manual/Test Fixture";
         when File_Diagnostic_Source     => return "File";
         when Project_Diagnostic_Source  => return "Project";
         when External_Diagnostic_Source => return "External Producer";
         when Unknown_Diagnostic_Source  => return "Unknown";
      end case;
   end Producer_Label;

   function Target_Unavailable_Label (Item : Diagnostic_Item) return String is
   begin
      if Item.Id = No_Diagnostic then
         return "Diagnostic target unavailable";
      elsif not Item.Has_Target
        and then Length (Item.Source_Label) = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif not Item.Has_Target
        and then Item.Target_Buffer /= No_Buffer
        and then Item.Target_Line = 0
      then
         return "Target line unavailable";
      elsif not Item.Has_Target
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line > 0
      then
         return "Target file missing";
      elsif not Item.Has_Target then
         return "Target file missing or unavailable";
      elsif Item.Target_Line = 0 then
         return "Target line unavailable";
      elsif Item.Target_Buffer = No_Buffer then
         return "Target file missing";
      elsif Item.Is_Stale then
         return Editor.Commands.Workflow_Messages.Reason_Target_Stale;
      else
         return "";
      end if;
   end Target_Unavailable_Label;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
   begin
      if Source'Length > 0 then
         return Source;
      elsif Item.Target_Buffer /= No_Buffer then
         return "Buffer " & Editor.Image_Helpers.Trim_Image (Item.Target_Buffer);
      else
         return "";
      end if;
   end Source_Filter_Label_For;

   function Source_Display_Label (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
      Position : constant String :=
        (if Item.Target_Line > 0 and then Item.Target_Column > 0 then
            Editor.Image_Helpers.Trim_Image (Item.Target_Line)
            & ":" & Editor.Image_Helpers.Trim_Image (Item.Target_Column)
         elsif Item.Target_Line > 0 then
            Editor.Image_Helpers.Trim_Image (Item.Target_Line)
         else
            "");
      Target_Source : constant String :=
        (if Source'Length > 0 then Source
         elsif Item.Target_Buffer /= No_Buffer then
            "Buffer " & Editor.Image_Helpers.Trim_Image (Item.Target_Buffer)
         else
            "");
   begin
      if Item.Has_Target then
         if Target_Source'Length = 0 then
            return Position;
         else
            return Target_Source & ":" & Position;
         end if;
      elsif Source'Length = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif Source'Length = 0 and then Item.Target_Buffer /= No_Buffer then
         return "Buffer " & Editor.Image_Helpers.Trim_Image (Item.Target_Buffer) &
           (if Position'Length > 0 then ":" & Position else "") &
           " — " & Target_Unavailable_Label (Item);
      elsif Position'Length > 0 then
         return Source & ":" & Position & " — " & Target_Unavailable_Label (Item);
      else
         return Source & " — " & Target_Unavailable_Label (Item);
      end if;
   end Source_Display_Label;

   function Stale_Label (Item : Diagnostic_Item) return String is
   begin
      if Item.Is_Stale then
         return "Stale diagnostic";
      else
         return "";
      end if;
   end Stale_Label;

   function Row_State_Label (Item : Diagnostic_Item) return String is
      Target_Label : constant String := Target_Unavailable_Label (Item);
   begin
      if Item.Is_Stale then
         return "stale";
      elsif Item.Has_Target
        and then Item.Target_Buffer /= No_Buffer
        and then Item.Target_Line > 0
      then
         return "openable";
      elsif Target_Label = "No source target" then
         return "no source";
      elsif Target_Label = "Target line unavailable" then
         return "missing line";
      elsif Target_Label = "Target file missing" then
         return "missing file";
      else
         return "unavailable";
      end if;
   end Row_State_Label;

   function Label_For (Item : Diagnostic_Item) return String is
   begin
      return Bounded_Text
        (Severity_Label (Item.Severity) & ": " & To_String (Item.Message) &
         " — " & Source_Display_Label (Item) &
         " [" & Producer_Label (Item) & "]" &
         (if Item.Is_Stale then " — stale" else ""),
         Max_Diagnostic_Message_Text_Length, "");
   end Label_For;

   function Detail_For (Item : Diagnostic_Item) return String is
      Target_Label : constant String := Target_Unavailable_Label (Item);
   begin
      return "state: " & Row_State_Label (Item) & " | " &
        Source_Display_Label (Item) &
        " | producer: " & Producer_Label (Item) &
        (if Length (Item.Quick_Fix_Label) > 0
         then " | action: " & To_String (Item.Quick_Fix_Label)
         elsif Item.Has_Edit then " | action: Apply edit"
         else "") &
        (if Length (Item.Quick_Fix_Detail) > 0
         then " | " & To_String (Item.Quick_Fix_Detail)
         else "") &
        (if Target_Label'Length = 0 then "" else " | " & Target_Label) &
        (if Item.Is_Stale then " | stale diagnostic" else "");
   end Detail_For;

   function Group_Label_For (Item : Diagnostic_Item) return String is
      Source : constant String := To_String (Item.Source_Label);
   begin
      if Source'Length = 0
        and then Item.Target_Buffer = No_Buffer
        and then Item.Target_Line = 0
      then
         return "No source target";
      elsif Source'Length = 0 and then Item.Target_Buffer /= No_Buffer then
         return "Buffer " & Editor.Image_Helpers.Trim_Image (Item.Target_Buffer) &
           (if Item.Has_Target then "" else " — " & Target_Unavailable_Label (Item));
      elsif Source'Length = 0 and then Item.Target_Line > 0 then
         return "Target file missing";
      elsif not Item.Has_Target then
         return Source & " — " & Target_Unavailable_Label (Item);
      else
         return Source;
      end if;
   end Group_Label_For;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Active :=
        Length (Diagnostics.Filter.Text) > 0
        or else Length (Diagnostics.Filter.Source_Text) > 0
        or else not Diagnostics.Filter.Show_Info
        or else not Diagnostics.Filter.Show_Notes
        or else not Diagnostics.Filter.Show_Warnings
        or else not Diagnostics.Filter.Show_Errors
        or else not Diagnostics.Filter.Show_Unknown_Severity
        or else not Diagnostics.Filter.Show_Editor
        or else not Diagnostics.Filter.Show_File
        or else not Diagnostics.Filter.Show_Project
        or else not Diagnostics.Filter.Show_External
        or else not Diagnostics.Filter.Show_Unknown
        or else Diagnostics.Filter.Build_Only;
   end Refresh_Filter_Active;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize_Diagnostics_Filter_Text;

   function Bounded_Text
     (Text        : String;
      Maximum     : Natural;
      Empty_Value : String) return String
   is
      Marker : constant String := "...";
      Clean  : constant String := (if Text'Length = 0 then Empty_Value else Text);
   begin
      if Clean'Length <= Maximum then
         return Clean;
      elsif Maximum <= Marker'Length then
         return Clean (Clean'First .. Clean'First + Maximum - 1);
      else
         return Clean (Clean'First .. Clean'First + Maximum - Marker'Length - 1) & Marker;
      end if;
   end Bounded_Text;

   function Normalize_Message (Message : String) return String is
   begin
      return Bounded_Text
        (Message, Max_Diagnostic_Message_Text_Length, "Diagnostic");
   end Normalize_Message;

   function Normalize_Source_Label (Source_Label : String) return String is
   begin
      return Bounded_Text
        (Source_Label, Max_Diagnostic_Source_Label_Text_Length, "");
   end Normalize_Source_Label;

   function Normalize_Replacement_Text (Replacement_Text : String) return String is
   begin
      return Bounded_Text
        (Replacement_Text, Max_Diagnostic_Message_Text_Length, "");
   end Normalize_Replacement_Text;

   function Normalize_Quick_Fix_Metadata (Text : String) return String is
   begin
      return Bounded_Text (Text, Max_Diagnostic_Message_Text_Length, "");
   end Normalize_Quick_Fix_Metadata;

   function Quick_Fix_Action_Model_For
     (Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Has_Edit : Boolean) return Diagnostic_Quick_Fix_Action_Model
   is
      Has_Command : constant Boolean :=
        Primary_Action_Kind /=
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None;
   begin
      if Has_Edit and then Has_Command then
         return Quick_Fix_Action_Edit_And_Command;
      elsif Has_Edit then
         return Quick_Fix_Action_Edit;
      elsif Has_Command then
         return Quick_Fix_Action_Command;
      else
         return Quick_Fix_Action_Unavailable;
      end if;
   end Quick_Fix_Action_Model_For;

   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String
   is
      package Projection renames Editor.Ada_Diagnostic_Command_Projection;
   begin
      case Kind is
         when Projection.Diagnostic_Command_Navigate_To_Diagnostic =>
            return "Navigate to diagnostic";
         when Projection.Diagnostic_Command_Explain_Diagnostic =>
            return "Explain diagnostic";
         when Projection.Diagnostic_Command_Review_Expression =>
            return "Review expression";
         when Projection.Diagnostic_Command_Review_Overload_Ranking =>
            return "Review overload ranking";
         when Projection.Diagnostic_Command_Review_Generic =>
            return "Review generic";
         when Projection.Diagnostic_Command_Review_Cross_Unit =>
            return "Review cross-unit context";
         when Projection.Diagnostic_Command_Review_Representation =>
            return "Review representation";
         when Projection.Diagnostic_Command_None =>
            return "Diagnostic action";
      end case;
   end Diagnostic_Action_Kind_Label;

   function Panel_Severity
     (Severity : Diagnostic_Severity) return Editor.Feature_Panel.Feature_Row_Severity
   is
   begin
      case Severity is
         when Diagnostic_Info | Diagnostic_Note | Diagnostic_Unknown =>
            return Editor.Feature_Panel.Feature_Row_Info_Severity;
         when Diagnostic_Warning =>
            return Editor.Feature_Panel.Feature_Row_Warning_Severity;
         when Diagnostic_Error =>
            return Editor.Feature_Panel.Feature_Row_Error_Severity;
      end case;
   end Panel_Severity;

end Editor.Feature_Diagnostics.Labels;
