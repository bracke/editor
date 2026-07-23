with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Image_Helpers;
with Editor.Feature_Diagnostics.Display;
with Editor.Feature_Diagnostics.Labels;

package body Editor.Feature_Diagnostics.Filtering is

   function Severity_Label (Severity : Diagnostic_Severity) return String
      renames Editor.Feature_Diagnostics.Display.Severity_Label;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String
      renames Editor.Feature_Diagnostics.Display.Source_Kind_Label;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean
      renames Editor.Feature_Diagnostics.Display.Is_Build_Produced_Item;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Display.Source_Filter_Label_For;

   function Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Label_For;

   function Detail_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Detail_For;

   function Group_Label_For (Item : Diagnostic_Item) return String
      renames Editor.Feature_Diagnostics.Labels.Group_Label_For;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String
      renames Editor.Feature_Diagnostics.Display.Normalize_Diagnostics_Filter_Text;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State)
      renames Editor.Feature_Diagnostics.Display.Refresh_Filter_Active;

   function Contains_Case_Insensitive
     (Haystack : String;
      Needle   : String) return Boolean
   is
      Normal_Haystack : constant String := Normalize_Diagnostics_Filter_Text (Haystack);
      Normal_Needle   : constant String := Normalize_Diagnostics_Filter_Text (Needle);
   begin
      return Normal_Needle'Length = 0
        or else Ada.Strings.Fixed.Index (Normal_Haystack, Normal_Needle) /= 0;
   end Contains_Case_Insensitive;

   function Diagnostic_Matches_Text_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive (To_String (Item.Message), Needle)
        or else Contains_Case_Insensitive (To_String (Item.Source_Label), Needle)
        or else Contains_Case_Insensitive (Severity_Label (Item.Severity), Needle)
        or else Contains_Case_Insensitive (Source_Kind_Label (Item.Source_Kind), Needle)
        or else Contains_Case_Insensitive (Label_For (Item), Needle)
        or else Contains_Case_Insensitive (Detail_For (Item), Needle);
   end Diagnostic_Matches_Text_Filter;

   function Diagnostic_Matches_Source_Label_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
      Needle : constant String := To_String (Diagnostics.Filter.Source_Text);
   begin
      if Needle'Length = 0 then
         return True;
      end if;

      return Contains_Case_Insensitive (Source_Filter_Label_For (Item), Needle);
   end Diagnostic_Matches_Source_Label_Filter;

   function Diagnostic_Matches_Severity_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Severity is
         when Diagnostic_Info    => return Diagnostics.Filter.Show_Info;
         when Diagnostic_Note    => return Diagnostics.Filter.Show_Notes;
         when Diagnostic_Warning => return Diagnostics.Filter.Show_Warnings;
         when Diagnostic_Error   => return Diagnostics.Filter.Show_Errors;
         when Diagnostic_Unknown => return Diagnostics.Filter.Show_Unknown_Severity;
      end case;
   end Diagnostic_Matches_Severity_Filter;

   function Diagnostic_Matches_Source_Filter
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      case Item.Source_Kind is
         when Editor_Diagnostic_Source   => return Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source     => return Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source  => return Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source => return Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source  => return Diagnostics.Filter.Show_Unknown;
      end case;
   end Diagnostic_Matches_Source_Filter;

   function Diagnostic_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Item        : Diagnostic_Item) return Boolean
   is
   begin
      return Diagnostic_Matches_Text_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Source_Label_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Severity_Filter (Diagnostics, Item)
        and then Diagnostic_Matches_Source_Filter (Diagnostics, Item)
        and then (not Diagnostics.Filter.Build_Only or else Is_Build_Produced_Item (Item));
   end Diagnostic_Is_Visible;

   function Severity_Order (Severity : Diagnostic_Severity) return Natural is
   begin
      case Severity is
         when Diagnostic_Error   => return 0;
         when Diagnostic_Warning => return 1;
         when Diagnostic_Info    => return 2;
         when Diagnostic_Note    => return 3;
         when Diagnostic_Unknown => return 4;
      end case;
   end Severity_Order;

   function Target_Line_Order (Item : Diagnostic_Item) return Natural is
   begin
      if Item.Target_Line > 0 then
         return Item.Target_Line;
      else
         return Natural'Last;
      end if;
   end Target_Line_Order;

   function Target_Column_Order (Item : Diagnostic_Item) return Natural is
   begin
      if Item.Target_Column > 0 then
         return Item.Target_Column;
      elsif Item.Target_Line > 0 then
         return 1;
      else
         return Natural'Last;
      end if;
   end Target_Column_Order;

   function Diagnostic_Comes_Before
     (Left  : Diagnostic_Item;
      Right : Diagnostic_Item) return Boolean
   is
      Left_Group  : constant String := Group_Label_For (Left);
      Right_Group : constant String := Group_Label_For (Right);
      Left_Line   : constant Natural := Target_Line_Order (Left);
      Right_Line  : constant Natural := Target_Line_Order (Right);
      Left_Column : constant Natural := Target_Column_Order (Left);
      Right_Column : constant Natural := Target_Column_Order (Right);
   begin
      if Left_Group /= Right_Group then
         return Left_Group < Right_Group;
      elsif Left_Line /= Right_Line then
         return Left_Line < Right_Line;
      elsif Left_Column /= Right_Column then
         return Left_Column < Right_Column;
      elsif Severity_Order (Left.Severity) /= Severity_Order (Right.Severity) then
         return Severity_Order (Left.Severity) < Severity_Order (Right.Severity);
      else
         return Left.Id < Right.Id;
      end if;
   end Diagnostic_Comes_Before;

   function Ordered_Visible_Indexes
     (Diagnostics : Diagnostics_Feature_State)
      return Visible_Row_Index_Vectors.Vector
   is
      Ordered : Visible_Row_Index_Vectors.Vector;
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Candidate : constant Diagnostic_Item :=
              Diagnostics.Rows.Element (I - 1);
            Inserted  : Boolean := False;
         begin
            if Diagnostic_Is_Visible (Diagnostics, Candidate) then
               if not Ordered.Is_Empty then
                  for Position in Ordered.First_Index .. Ordered.Last_Index loop
                     declare
                        Existing_Index : constant Natural :=
                          Ordered.Element (Position);
                        Existing : constant Diagnostic_Item :=
                          Diagnostics.Rows.Element (Existing_Index - 1);
                     begin
                        if Diagnostic_Comes_Before (Candidate, Existing) then
                           Ordered.Insert (Position, I);
                           Inserted := True;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;

               if not Inserted then
                  Ordered.Append (I);
               end if;
            end if;
         end;
      end loop;

      return Ordered;
   end Ordered_Visible_Indexes;

   function Ordered_Visible_Index_At
     (Diagnostics : Diagnostics_Feature_State;
      Position    : Positive) return Natural
   is
      Ordered : constant Visible_Row_Index_Vectors.Vector :=
        Ordered_Visible_Indexes (Diagnostics);
   begin
      if Position > Natural (Ordered.Length) then
         return 0;
      end if;

      return Ordered.Element (Position - 1);
   end Ordered_Visible_Index_At;

   function Visible_Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostic_Is_Visible (Diagnostics, Diagnostics.Rows.Element (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Visible_Row_Count;

   function Severity_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
   is
   begin
      case Severity is
         when Diagnostic_Info    => return Diagnostics.Filter.Show_Info;
         when Diagnostic_Note    => return Diagnostics.Filter.Show_Notes;
         when Diagnostic_Warning => return Diagnostics.Filter.Show_Warnings;
         when Diagnostic_Error   => return Diagnostics.Filter.Show_Errors;
         when Diagnostic_Unknown => return Diagnostics.Filter.Show_Unknown_Severity;
      end case;
   end Severity_Is_Visible;

   function Source_Is_Visible
     (Diagnostics : Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind) return Boolean
   is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source   => return Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source     => return Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source  => return Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source => return Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source  => return Diagnostics.Filter.Show_Unknown;
      end case;
   end Source_Is_Visible;

   function Filter_Active
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Diagnostics.Filter.Active;
   end Filter_Active;

   function Filter_Text
     (Diagnostics : Diagnostics_Feature_State) return String
   is
   begin
      return To_String (Diagnostics.Filter.Text);
   end Filter_Text;

   procedure Set_Filter_Text
     (Diagnostics : in out Diagnostics_Feature_State;
      Text        : String)
   is
   begin
      Diagnostics.Filter.Text :=
        To_Unbounded_String (Normalize_Diagnostics_Filter_Text (Text));
      Diagnostics.Filter.Source_Text := Null_Unbounded_String;
      Refresh_Filter_Active (Diagnostics);
   end Set_Filter_Text;

   procedure Show_All
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Text := Null_Unbounded_String;
      Diagnostics.Filter.Source_Text := Null_Unbounded_String;
      Diagnostics.Filter.Show_Info := True;
      Diagnostics.Filter.Show_Notes := True;
      Diagnostics.Filter.Show_Warnings := True;
      Diagnostics.Filter.Show_Errors := True;
      Diagnostics.Filter.Show_Unknown_Severity := True;
      Diagnostics.Filter.Show_Editor := True;
      Diagnostics.Filter.Show_File := True;
      Diagnostics.Filter.Show_Project := True;
      Diagnostics.Filter.Show_External := True;
      Diagnostics.Filter.Show_Unknown := True;
      Diagnostics.Filter.Build_Only := False;
      Refresh_Filter_Active (Diagnostics);
   end Show_All;

   procedure Clear_Filter
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
   end Clear_Filter;

   procedure Toggle_Info_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
      New_Visibility : constant Boolean := not Diagnostics.Filter.Show_Info;
   begin
      Diagnostics.Filter.Show_Info := New_Visibility;
      Diagnostics.Filter.Show_Notes := New_Visibility;
      Refresh_Filter_Active (Diagnostics);
   end Toggle_Info_Visible;

   procedure Toggle_Warnings_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Show_Warnings := not Diagnostics.Filter.Show_Warnings;
      Refresh_Filter_Active (Diagnostics);
   end Toggle_Warnings_Visible;

   procedure Toggle_Errors_Visible
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Diagnostics.Filter.Show_Errors := not Diagnostics.Filter.Show_Errors;
      Refresh_Filter_Active (Diagnostics);
   end Toggle_Errors_Visible;

   procedure Toggle_Source_Visible
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Kind : Diagnostic_Source_Kind)
   is
   begin
      case Source_Kind is
         when Editor_Diagnostic_Source =>
            Diagnostics.Filter.Show_Editor := not Diagnostics.Filter.Show_Editor;
         when File_Diagnostic_Source =>
            Diagnostics.Filter.Show_File := not Diagnostics.Filter.Show_File;
         when Project_Diagnostic_Source =>
            Diagnostics.Filter.Show_Project := not Diagnostics.Filter.Show_Project;
         when External_Diagnostic_Source =>
            Diagnostics.Filter.Show_External := not Diagnostics.Filter.Show_External;
         when Unknown_Diagnostic_Source =>
            Diagnostics.Filter.Show_Unknown := not Diagnostics.Filter.Show_Unknown;
      end case;
      Refresh_Filter_Active (Diagnostics);
   end Toggle_Source_Visible;

   function Count_By_Severity
     (Diagnostics : Diagnostics_Feature_State) return Diagnostics_Severity_Counts
   is
      Counts : Diagnostics_Severity_Counts;
   begin
      Counts.Total := Row_Count (Diagnostics);
      Counts.Visible := Visible_Row_Count (Diagnostics);
      for I in 1 .. Row_Count (Diagnostics) loop
         declare
            Item : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
            Is_Visible : constant Boolean := Diagnostic_Is_Visible (Diagnostics, Item);
         begin
            case Item.Severity is
               when Diagnostic_Error =>
                  Counts.Errors := Counts.Errors + 1;
                  if Is_Visible then
                     Counts.Visible_Errors := Counts.Visible_Errors + 1;
                  end if;
               when Diagnostic_Warning =>
                  Counts.Warnings := Counts.Warnings + 1;
                  if Is_Visible then
                     Counts.Visible_Warnings := Counts.Visible_Warnings + 1;
                  end if;
               when Diagnostic_Info =>
                  Counts.Info := Counts.Info + 1;
                  if Is_Visible then
                     Counts.Visible_Info := Counts.Visible_Info + 1;
                  end if;
               when Diagnostic_Note =>
                  Counts.Notes := Counts.Notes + 1;
                  if Is_Visible then
                     Counts.Visible_Notes := Counts.Visible_Notes + 1;
                  end if;
               when Diagnostic_Unknown =>
                  Counts.Unknown := Counts.Unknown + 1;
                  if Is_Visible then
                     Counts.Visible_Unknown := Counts.Visible_Unknown + 1;
                  end if;
            end case;
         end;
      end loop;
      return Counts;
   end Count_By_Severity;

   function Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
   is
   begin
      return "Errors: " & Editor.Image_Helpers.Trim_Image (Counts.Errors) &
        " | Warnings: " & Editor.Image_Helpers.Trim_Image (Counts.Warnings) &
        " | Info: " & Editor.Image_Helpers.Trim_Image (Counts.Info) &
        " | Notes: " & Editor.Image_Helpers.Trim_Image (Counts.Notes) &
        " | Unknown: " & Editor.Image_Helpers.Trim_Image (Counts.Unknown) &
        " | Total: " & Editor.Image_Helpers.Trim_Image (Counts.Total);
   end Count_Label;

   function Visible_Count_Label
     (Counts : Diagnostics_Severity_Counts) return String
   is
   begin
      return "Visible Errors: " & Editor.Image_Helpers.Trim_Image (Counts.Visible_Errors) &
        " | Visible Warnings: " & Editor.Image_Helpers.Trim_Image (Counts.Visible_Warnings) &
        " | Visible Info: " & Editor.Image_Helpers.Trim_Image (Counts.Visible_Info) &
        " | Visible Notes: " & Editor.Image_Helpers.Trim_Image (Counts.Visible_Notes) &
        " | Visible Unknown: " & Editor.Image_Helpers.Trim_Image (Counts.Visible_Unknown) &
        " | Visible Total: " & Editor.Image_Helpers.Trim_Image (Counts.Visible);
   end Visible_Count_Label;

   function Visible_File_Groups
     (Diagnostics : Diagnostics_Feature_State)
      return Diagnostics_File_Group_Vectors.Vector
   is
      Groups : Diagnostics_File_Group_Vectors.Vector;
   begin
      declare
         Ordered : constant Visible_Row_Index_Vectors.Vector :=
           Ordered_Visible_Indexes (Diagnostics);
      begin
         for Position in Ordered.First_Index .. Ordered.Last_Index loop
            declare
               I     : constant Natural := Ordered.Element (Position);
               Item   : constant Diagnostic_Item := Diagnostics.Rows.Element (I - 1);
               Source : constant String := To_String (Item.Source_Label);
               Label  : constant String := Group_Label_For (Item);
               Found  : Boolean := False;
            begin
               if not Groups.Is_Empty then
                  for G in Groups.First_Index .. Groups.Last_Index loop
                     declare
                        Existing : Diagnostics_File_Group := Groups.Element (G);
                     begin
                        if To_String (Existing.Label) = Label then
                           Existing.Diagnostic_Count := Existing.Diagnostic_Count + 1;
                           if Item.Severity = Diagnostic_Error then
                              Existing.Error_Count := Existing.Error_Count + 1;
                           elsif Item.Severity = Diagnostic_Warning then
                              Existing.Warning_Count := Existing.Warning_Count + 1;
                           end if;
                           Groups.Replace_Element (G, Existing);
                           Found := True;
                        end if;
                     end;
                  end loop;
               end if;

               if not Found then
                  Groups.Append
                    (Diagnostics_File_Group'
                      (Label            => To_Unbounded_String (Label),
                       Diagnostic_Count => 1,
                       Error_Count      => (if Item.Severity = Diagnostic_Error then 1 else 0),
                       Warning_Count    => (if Item.Severity = Diagnostic_Warning then 1 else 0),
                       Source_Less      => Source'Length = 0
                         and then not Item.Has_Target
                         and then Item.Target_Buffer = No_Buffer
                         and then Item.Target_Line = 0));
               end if;
            end;
         end loop;
      end;
      return Groups;
   end Visible_File_Groups;

   function File_Group_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
   begin
      return Natural (Visible_File_Groups (Diagnostics).Length);
   end File_Group_Count;

   function File_Group_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String
   is
      Groups : constant Diagnostics_File_Group_Vectors.Vector :=
        Visible_File_Groups (Diagnostics);
      Group  : Diagnostics_File_Group;
   begin
      if Index = 0 or else Index > Natural (Groups.Length) then
         return "";
      end if;
      Group := Groups.Element (Index - 1);
      return To_String (Group.Label) & " ("
        & Editor.Image_Helpers.Trim_Image (Group.Diagnostic_Count)
        & " diagnostics, "
        & Editor.Image_Helpers.Trim_Image (Group.Error_Count)
        & " errors, "
        & Editor.Image_Helpers.Trim_Image (Group.Warning_Count)
        & " warnings)";
   end File_Group_Label;

   function Header_Text
     (Diagnostics : Diagnostics_Feature_State) return String
   is
      Counts : constant Diagnostics_Severity_Counts := Count_By_Severity (Diagnostics);
   begin
      if Counts.Total = 0 then
         return "No diagnostics.";
      elsif Filter_Active (Diagnostics) then
         return "Diagnostics: " & Editor.Image_Helpers.Trim_Image (Counts.Visible) & " of " &
           Editor.Image_Helpers.Trim_Image (Counts.Total) & " visible | " &
           Visible_Count_Label (Counts) & " | " & Count_Label (Counts);
      else
         return "Diagnostics: " & Count_Label (Counts);
      end if;
   end Header_Text;

   function Has_Visible_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Visible_Row_Count (Diagnostics) > 0;
   end Has_Visible_Diagnostic;

   function Build_Diagnostic_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Is_Build_Produced_Item (Diagnostics.Rows.Element (I - 1)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Build_Diagnostic_Count;

   function Has_Diagnostic_With_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Severity    : Diagnostic_Severity) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostics.Rows.Element (I - 1).Severity = Severity then
            return True;
         end if;
      end loop;
      return False;
   end Has_Diagnostic_With_Severity;

   function Has_Info_Or_Note_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Diagnostics) loop
         if Diagnostics.Rows.Element (I - 1).Severity = Diagnostic_Info
           or else Diagnostics.Rows.Element (I - 1).Severity = Diagnostic_Note
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Info_Or_Note_Diagnostic;

   function Has_Build_Diagnostic
     (Diagnostics : Diagnostics_Feature_State) return Boolean
   is
   begin
      return Build_Diagnostic_Count (Diagnostics) > 0;
   end Has_Build_Diagnostic;

   procedure Filter_Errors_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := False;
      Diagnostics.Filter.Show_Notes := False;
      Diagnostics.Filter.Show_Warnings := False;
      Diagnostics.Filter.Show_Errors := True;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
   end Filter_Errors_Only;

   procedure Filter_Warnings_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := False;
      Diagnostics.Filter.Show_Notes := False;
      Diagnostics.Filter.Show_Warnings := True;
      Diagnostics.Filter.Show_Errors := False;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
   end Filter_Warnings_Only;

   procedure Filter_Info_And_Notes_Only
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Show_Info := True;
      Diagnostics.Filter.Show_Notes := True;
      Diagnostics.Filter.Show_Warnings := False;
      Diagnostics.Filter.Show_Errors := False;
      Diagnostics.Filter.Show_Unknown_Severity := False;
      Refresh_Filter_Active (Diagnostics);
   end Filter_Info_And_Notes_Only;

   procedure Filter_Build_Produced
     (Diagnostics : in out Diagnostics_Feature_State)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Build_Only := True;
      Refresh_Filter_Active (Diagnostics);
   end Filter_Build_Produced;

   procedure Filter_Source_Label
     (Diagnostics : in out Diagnostics_Feature_State;
      Source_Text : String)
   is
   begin
      Show_All (Diagnostics);
      Diagnostics.Filter.Text := Null_Unbounded_String;
      Diagnostics.Filter.Source_Text :=
        To_Unbounded_String (Normalize_Diagnostics_Filter_Text (Source_Text));
      Refresh_Filter_Active (Diagnostics);
   end Filter_Source_Label;

end Editor.Feature_Diagnostics.Filtering;
