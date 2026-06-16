with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Feature_Panel is

   type Feature_Descriptor_Table is array (Positive range <>) of Feature_Descriptor;

   --  Single source of truth for registered feature-panel-backed features.
   --  Keep this table explicit and small; Phase 158 freezes the four-feature
   --  built-in descriptor set, not a dynamic plugin registry.
   Feature_Descriptors : constant Feature_Descriptor_Table :=
     (1 =>
        (Id            => Outline_Feature,
         Stable_Name   => To_Unbounded_String ("outline"),
         Display_Label => To_Unbounded_String ("Outline"),
         Supports_Rows => True,
         Can_Clear     => True),
      2 =>
        (Id            => Messages_Feature,
         Stable_Name   => To_Unbounded_String ("messages"),
         Display_Label => To_Unbounded_String ("Messages"),
         Supports_Rows => True,
         Can_Clear     => True),
      3 =>
        (Id            => Search_Results_Feature,
         Stable_Name   => To_Unbounded_String ("search-results"),
         Display_Label => To_Unbounded_String ("Search Results"),
         Supports_Rows => True,
         Can_Clear     => True),
      4 =>
        (Id            => Diagnostics_Feature,
         Stable_Name   => To_Unbounded_String ("diagnostics"),
         Display_Label => To_Unbounded_String ("Diagnostics"),
         Supports_Rows => True,
         Can_Clear     => True));

   Unknown_Descriptor : constant Feature_Descriptor :=
     (Id            => Unknown_Feature,
      Stable_Name   => Null_Unbounded_String,
      Display_Label => Null_Unbounded_String,
      Supports_Rows => False,
      Can_Clear     => False);

   function Descriptor_For (Feature : Feature_Id) return Feature_Descriptor is
   begin
      for Descriptor of Feature_Descriptors loop
         if Descriptor.Id = Feature then
            return Descriptor;
         end if;
      end loop;

      return Unknown_Descriptor;
   end Descriptor_For;

   function Is_Known_Feature (Feature : Feature_Id) return Boolean is
   begin
      return Descriptor_For (Feature).Id /= Unknown_Feature;
   end Is_Known_Feature;

   function Feature_Descriptor_Count return Natural is
   begin
      return Feature_Descriptors'Length;
   end Feature_Descriptor_Count;

   function Descriptor_Id (Index : Positive) return Feature_Id is
   begin
      if Index in Feature_Descriptors'Range then
         return Feature_Descriptors (Index).Id;
      end if;

      return Unknown_Feature;
   end Descriptor_Id;

   function Feature_Stable_Name (Feature : Feature_Id) return String is
   begin
      return To_String (Descriptor_For (Feature).Stable_Name);
   end Feature_Stable_Name;

   function Feature_Display_Label (Feature : Feature_Id) return String is
   begin
      return To_String (Descriptor_For (Feature).Display_Label);
   end Feature_Display_Label;

   function Feature_Supports_Rows (Feature : Feature_Id) return Boolean is
   begin
      return Descriptor_For (Feature).Supports_Rows;
   end Feature_Supports_Rows;

   function Feature_Can_Clear (Feature : Feature_Id) return Boolean is
   begin
      return Descriptor_For (Feature).Can_Clear;
   end Feature_Can_Clear;


   function To_Row
     (Kind              : Feature_Panel_Row_Kind;
      Label             : String;
      Detail            : String := "";
      Is_Current_Symbol : Boolean := False;
      Selectable        : Boolean := True;
      Activatable       : Boolean := False;
      Has_Target        : Boolean := False;
      Is_Diagnostic     : Boolean := False;
      Can_Open          : Boolean := False;
      Can_Copy          : Boolean := False;
      Can_Clear         : Boolean := False;
      Can_Reveal        : Boolean := False;
      Action_Id         : Feature_Action_Id := No_Feature_Action;
      Source_Index      : Natural := 0;
      Severity          : Feature_Row_Severity := Feature_Row_No_Severity) return Feature_Panel_Row
   is
   begin
      return
        (Kind              => Kind,
         Label             => To_Unbounded_String (Label),
         Detail            => To_Unbounded_String (Detail),
         Is_Current_Symbol => Is_Current_Symbol,
         Selectable        => Selectable,
         Activatable       => Activatable,
         Has_Target        => Has_Target,
         Is_Diagnostic     => Is_Diagnostic,
         Can_Open          => Can_Open,
         Can_Copy          => Can_Copy,
         Can_Clear         => Can_Clear,
         Can_Reveal        => Can_Reveal,
         Is_Selected       => False,
         Action_Id         => Action_Id,
         Source_Index      => Source_Index,
         Severity          => Severity);
   end To_Row;

   function To_Render_Row
     (Row      : Feature_Panel_Row;
      Selected : Boolean) return Feature_Panel_Render_Row
   is
   begin
      return
        (Kind              => Row.Kind,
         Label             => Row.Label,
         Detail            => Row.Detail,
         Selected          => Selected,
         Is_Current_Symbol => Row.Is_Current_Symbol,
         Selectable        => Row.Selectable,
         Activatable       => Row.Activatable,
         Has_Target        => Row.Has_Target,
         Is_Diagnostic     => Row.Is_Diagnostic,
         Can_Open          => Row.Can_Open,
         Can_Copy          => Row.Can_Copy,
         Can_Clear         => Row.Can_Clear,
         Can_Reveal        => Row.Can_Reveal,
         Action_Id         => Row.Action_Id,
         Source_Index      => Row.Source_Index,
         Severity          => Row.Severity);
   end To_Render_Row;

   procedure Bump_Projection_Generation
     (Panel : in out Feature_Panel_State);

   procedure Assert_Invariant
     (Panel   : Feature_Panel_State;
      Context : String);

   function Active_Feature (Panel : Feature_Panel_State) return Feature_Id is
   begin
      if Is_Known_Feature (Panel.Active_Feature_Id) then
         return Panel.Active_Feature_Id;
      end if;
      return Outline_Feature;
   end Active_Feature;

   procedure Save_Active_Feature_View_State
     (Panel : in out Feature_Panel_State)
   is
      Feature : constant Feature_Id := Active_Feature (Panel);
   begin
      if Is_Known_Feature (Feature) then
         Panel.Saved_View_State (Feature) :=
           (Has_State         => True,
            Selected_Row      => Selected_Row (Panel),
            First_Visible_Row => First_Visible_Row (Panel));
      end if;
      Assert_Invariant (Panel, "Save_Active_Feature_View_State");
   end Save_Active_Feature_View_State;

   procedure Clamp_Visible_Viewport_Only
     (Panel : in out Feature_Panel_State)
   is
      Count    : constant Natural := Row_Count (Panel);
      Last_Top : Natural := 1;
   begin
      if Count = 0 then
         Panel.Selected := 0;
         Panel.Reveal_Row := 0;
         Panel.First_Visible_Row := 1;
         return;
      end if;

      if Panel.Selected > Count
        or else (Panel.Selected /= 0
                 and then not Row_Is_Selectable (Panel, Positive (Panel.Selected)))
      then
         Panel.Selected := 0;
      end if;

      if Panel.Reveal_Row > Count then
         Panel.Reveal_Row := 0;
      end if;

      if Count > Panel.Visible_Row_Count then
         Last_Top := Count - Panel.Visible_Row_Count + 1;
      end if;

      if Panel.First_Visible_Row = 0 then
         Panel.First_Visible_Row := 1;
      elsif Panel.First_Visible_Row > Last_Top then
         Panel.First_Visible_Row := Last_Top;
      end if;
   end Clamp_Visible_Viewport_Only;

   procedure Restore_Active_Feature_View_State
     (Panel : in out Feature_Panel_State)
   is
      Feature : constant Feature_Id := Active_Feature (Panel);
      Saved   : Saved_Feature_View_State;
      Count   : constant Natural := Row_Count (Panel);
      Last_Top : Natural := 1;
   begin
      if not Is_Known_Feature (Feature) then
         Assert_Invariant (Panel, "Restore_Active_Feature_View_State unknown");
         return;
      end if;

      Saved := Panel.Saved_View_State (Feature);
      if not Saved.Has_State then
         Clamp_Visible_Viewport_Only (Panel);
         Assert_Invariant (Panel, "Restore_Active_Feature_View_State none");
         return;
      end if;

      if Count = 0 then
         Panel.Selected := 0;
         Panel.First_Visible_Row := 1;
         Panel.Reveal_Row := 0;
      else
         if Saved.Selected_Row >= 1
           and then Saved.Selected_Row <= Count
           and then Row_Is_Selectable (Panel, Positive (Saved.Selected_Row))
         then
            Panel.Selected := Saved.Selected_Row;
         else
            Panel.Selected := 0;
         end if;

         if Count > Panel.Visible_Row_Count then
            Last_Top := Count - Panel.Visible_Row_Count + 1;
         end if;

         if Saved.First_Visible_Row < 1 then
            Panel.First_Visible_Row := 1;
         elsif Saved.First_Visible_Row > Last_Top then
            Panel.First_Visible_Row := Last_Top;
         else
            Panel.First_Visible_Row := Saved.First_Visible_Row;
         end if;

         if Panel.Reveal_Row > Count then
            Panel.Reveal_Row := 0;
         end if;
      end if;

      Assert_Invariant (Panel, "Restore_Active_Feature_View_State");
   end Restore_Active_Feature_View_State;

   procedure Forget_Feature_View_State
     (Panel   : in out Feature_Panel_State;
      Feature : Feature_Id)
   is
   begin
      if Is_Known_Feature (Feature) then
         Panel.Saved_View_State (Feature) :=
           (Has_State         => False,
            Selected_Row      => 0,
            First_Visible_Row => 1);
      end if;
      Assert_Invariant (Panel, "Forget_Feature_View_State");
   end Forget_Feature_View_State;

   procedure Forget_Active_Feature_View_State
     (Panel : in out Feature_Panel_State)
   is
   begin
      Forget_Feature_View_State (Panel, Active_Feature (Panel));
      Assert_Invariant (Panel, "Forget_Active_Feature_View_State");
   end Forget_Active_Feature_View_State;

   procedure Clear_Visible_Selection_For_Feature_Switch
     (Panel : in out Feature_Panel_State)
   is
   begin
      Panel.Selected := 0;
      Panel.Reveal_Row := 0;
      Panel.First_Visible_Row := 1;
      Assert_Invariant (Panel, "Clear_Visible_Selection_For_Feature_Switch");
   end Clear_Visible_Selection_For_Feature_Switch;

   function Set_Active_Feature
     (Panel   : in out Feature_Panel_State;
      Feature : Feature_Id) return Boolean
   is
   begin
      if not Is_Known_Feature (Feature) then
         return False;
      end if;

      if Panel.Active_Feature_Id /= Feature then
         Save_Active_Feature_View_State (Panel);
         Panel.Active_Feature_Id := Feature;
         Clear_Visible_Selection_For_Feature_Switch (Panel);
         Bump_Projection_Generation (Panel);
      end if;
      Panel.Header := To_Unbounded_String (Feature_Display_Label (Feature));
      Assert_Invariant (Panel, "Set_Active_Feature");
      return True;
   end Set_Active_Feature;

   function Build_Feature_Projection_Token
     (Panel : Feature_Panel_State) return Feature_Projection_Token
   is
   begin
      return (Feature => Active_Feature (Panel),
              Generation => Projection_Generation (Panel));
   end Build_Feature_Projection_Token;

   function Validate_Feature_Projection_Token
     (Panel : Feature_Panel_State;
      Token : Feature_Projection_Token) return Boolean
   is
   begin
      return Is_Known_Feature (Token.Feature)
        and then Token.Feature = Active_Feature (Panel)
        and then Token.Generation /= 0
        and then Token.Generation = Projection_Generation (Panel);
   end Validate_Feature_Projection_Token;

   function Invariant_Holds
     (Panel : Feature_Panel_State) return Boolean
   is
      Count : constant Natural := Natural (Panel.Rows.Length);
   begin
      if not Is_Known_Feature (Panel.Active_Feature_Id) then
         return False;
      end if;

      if Panel.Focused and then not Panel.Visible then
         return False;
      end if;

      if Panel.Visible_Row_Count = 0 then
         return False;
      end if;

      if Count = 0 then
         return Panel.Selected = 0
           and then Panel.Reveal_Row = 0
           and then Panel.First_Visible_Row = 1;
      end if;

      return Panel.Selected <= Count
        and then Panel.Reveal_Row <= Count
        and then Panel.First_Visible_Row >= 1
        and then Panel.First_Visible_Row <= Count;
   end Invariant_Holds;

   function Summary
     (Panel : Feature_Panel_State) return Feature_Panel_Summary
   is
      Selected : constant Natural := Selected_Row (Panel);
   begin
      return
        (Visible       => Panel.Visible,
         Focused       => Panel.Focused and then Panel.Visible,
         Row_Count         => Natural (Panel.Rows.Length),
         Has_Selection     => Selected /= 0,
         Selected_Row      => Selected,
         First_Visible_Row => Panel.First_Visible_Row,
         Visible_Row_Count => Panel.Visible_Row_Count);
   end Summary;

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Natural ((Long_Long_Integer (H) * 131 + Long_Long_Integer (Character'Pos (C)) + 1) mod 2_147_483_647);
      end loop;
      return H;
   end Hash_String;

   function Fingerprint
     (Panel : Feature_Panel_State) return Feature_Panel_Fingerprint
   is
      S : constant Feature_Panel_Summary := Summary (Panel);
      Labels  : Natural := 17;
      Details : Natural := 29;
   begin
      for I in 1 .. Row_Count (Panel) loop
         Labels := Hash_String (Labels, Row_Label (Panel, I));
         Details := Hash_String (Details, Row_Detail (Panel, I));
      end loop;
      return
        (Visible          => S.Visible,
         Focused          => S.Focused,
         Row_Count        => S.Row_Count,
         Has_Selection    => S.Has_Selection,
         Selected_Row     => S.Selected_Row,
         Row_Labels_Hash  => Labels,
         Row_Details_Hash => Details);
   end Fingerprint;

   function Is_Selected_Row
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      return Selected_Row (Panel) = Index;
   end Is_Selected_Row;

   function Debug_Summary
     (Panel : Feature_Panel_State) return String
   is
   begin
      return "visible=" & Boolean'Image (Panel.Visible)
        & ", focused=" & Boolean'Image (Panel.Focused)
        & ", rows=" & Natural'Image (Natural (Panel.Rows.Length))
        & ", selected=" & Natural'Image (Panel.Selected)
        & ", reveal=" & Natural'Image (Panel.Reveal_Row)
        & ", first_visible=" & Natural'Image (Panel.First_Visible_Row)
        & ", visible_count=" & Natural'Image (Panel.Visible_Row_Count)
        & ", invariant=" & Boolean'Image (Invariant_Holds (Panel));
   end Debug_Summary;

   procedure Assert_Invariant
     (Panel   : Feature_Panel_State;
      Context : String)
   is
   begin
      pragma Assert
        (Invariant_Holds (Panel),
         "Feature_Panel invariant failed after " & Context & ": " &
           Debug_Summary (Panel));
   end Assert_Invariant;

   procedure Clamp_Selection
     (Panel : in out Feature_Panel_State)
   is
      Count : constant Natural := Natural (Panel.Rows.Length);
      Last_Top : Natural := 1;
   begin
      if Count = 0 then
         Panel.Selected := 0;
      elsif Panel.Selected > Count
        or else (Panel.Selected /= 0
                 and then not Row_Is_Selectable (Panel, Positive (Panel.Selected)))
      then
         Panel.Selected := 0;
      end if;

      if Panel.Reveal_Row > Count then
         Panel.Reveal_Row := 0;
      end if;

      if Count > Panel.Visible_Row_Count then
         Last_Top := Count - Panel.Visible_Row_Count + 1;
      end if;

      if Count = 0 then
         Panel.First_Visible_Row := 1;
      elsif Panel.First_Visible_Row = 0 then
         Panel.First_Visible_Row := 1;
      elsif Panel.First_Visible_Row > Last_Top then
         Panel.First_Visible_Row := Last_Top;
      end if;
   end Clamp_Selection;

   procedure Bump_Projection_Generation
     (Panel : in out Feature_Panel_State)
   is
   begin
      if Panel.Projection_Generation = Natural'Last then
         Panel.Projection_Generation := 1;
      else
         Panel.Projection_Generation := Panel.Projection_Generation + 1;
      end if;
   end Bump_Projection_Generation;

   procedure Clear
     (Panel : in out Feature_Panel_State)
   is
   begin
      Panel.Visible := False;
      Panel.Focused := False;
      Panel.Active_Feature_Id := Outline_Feature;
      Clear_Rows (Panel);
      Assert_Invariant (Panel, "Clear");
   end Clear;

   procedure Reset_For_Project_Close
     (Panel : in out Feature_Panel_State)
   is
   begin
      Clear_Rows (Panel);
      Panel.Focused := False;
      Assert_Invariant (Panel, "Reset_For_Project_Close");
   end Reset_For_Project_Close;

   procedure Set_Visible
     (Panel   : in out Feature_Panel_State;
      Visible : Boolean)
   is
   begin
      Panel.Visible := Visible;
      if not Visible then
         Panel.Focused := False;
      end if;
      Assert_Invariant (Panel, "Set_Visible");
   end Set_Visible;

   function Is_Visible
     (Panel : Feature_Panel_State) return Boolean
   is
   begin
      return Panel.Visible;
   end Is_Visible;

   procedure Set_Focused
     (Panel   : in out Feature_Panel_State;
      Focused : Boolean)
   is
   begin
      Panel.Focused := Focused and then Panel.Visible;
      Assert_Invariant (Panel, "Set_Focused");
   end Set_Focused;

   function Is_Focused
     (Panel : Feature_Panel_State) return Boolean
   is
   begin
      return Panel.Focused and then Panel.Visible;
   end Is_Focused;

   procedure Clear_Rows
     (Panel : in out Feature_Panel_State)
   is
      Changed : constant Boolean :=
        Panel.Rows.Length > 0
        or else Panel.Selected /= 0
        or else Panel.Reveal_Row /= 0
        or else Panel.First_Visible_Row /= 1;
   begin
      Panel.Rows.Clear;
      Panel.Selected := 0;
      Panel.Reveal_Row := 0;
      Panel.First_Visible_Row := 1;
      if Changed then
         Bump_Projection_Generation (Panel);
      end if;
      Assert_Invariant (Panel, "Clear_Rows");
   end Clear_Rows;

   procedure Set_Header_Text
     (Panel : in out Feature_Panel_State;
      Text  : String)
   is
   begin
      if To_String (Panel.Header) /= Text then
         Panel.Header := To_Unbounded_String (Text);
      end if;
      Assert_Invariant (Panel, "Set_Header_Text");
   end Set_Header_Text;

   function Header_Text
     (Panel : Feature_Panel_State) return String
   is
   begin
      return To_String (Panel.Header);
   end Header_Text;

   procedure Append_Row
     (Panel             : in out Feature_Panel_State;
      Kind              : Feature_Panel_Row_Kind;
      Label             : String;
      Detail            : String := "";
      Is_Current_Symbol : Boolean := False;
      Selectable        : Boolean := True;
      Activatable       : Boolean := False;
      Has_Target        : Boolean := False;
      Is_Diagnostic     : Boolean := False;
      Can_Open          : Boolean := False;
      Can_Copy          : Boolean := False;
      Can_Clear         : Boolean := False;
      Can_Reveal        : Boolean := False;
      Action_Id         : Feature_Action_Id := No_Feature_Action;
      Source_Index      : Natural := 0;
      Severity          : Feature_Row_Severity := Feature_Row_No_Severity)
   is
   begin
      Panel.Rows.Append
        (To_Row
           (Kind, Label, Detail, Is_Current_Symbol, Selectable,
            Activatable, Has_Target, Is_Diagnostic, Can_Open, Can_Copy, Can_Clear,
            Can_Reveal, Action_Id, Source_Index, Severity));
      Bump_Projection_Generation (Panel);
      Assert_Invariant (Panel, "Append_Row");
   end Append_Row;

   function Projection_Generation
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      return Panel.Projection_Generation;
   end Projection_Generation;

   function Projection_Generation_Matches
     (Panel    : Feature_Panel_State;
      Expected : Natural) return Boolean
   is
   begin
      return Expected = 0 or else Expected = Projection_Generation (Panel);
   end Projection_Generation_Matches;

   function Projection_Token_Matches
     (Panel : Feature_Panel_State;
      Token : Feature_Projection_Token) return Boolean
   is
   begin
      return Validate_Feature_Projection_Token (Panel, Token);
   end Projection_Token_Matches;

   function Projection_Row_Index_Is_Valid
     (Panel : Feature_Panel_State;
      Row   : Natural) return Boolean
   is
   begin
      return Row >= 1 and then Row <= Row_Count (Panel);
   end Projection_Row_Index_Is_Valid;

   function Reveal_Row_Index_Is_Valid
     (Panel : Feature_Panel_State;
      Row   : Natural) return Boolean
   is
   begin
      return Projection_Row_Index_Is_Valid (Panel, Row);
   end Reveal_Row_Index_Is_Valid;

   function Row_Is_Selectable
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Selectable;
   end Row_Is_Selectable;

   function Has_Selectable_Row
     (Panel : Feature_Panel_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Panel) loop
         if Row_Is_Selectable (Panel, I) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Selectable_Row;

   function Row_Is_Activatable
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Activatable;
   end Row_Is_Activatable;

   function Row_Has_Target
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Has_Target;
   end Row_Has_Target;

   function Row_Is_Diagnostic
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Is_Diagnostic;
   end Row_Is_Diagnostic;

   function Row_Can_Open
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Can_Open;
   end Row_Can_Open;

   function Row_Can_Copy
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Can_Copy;
   end Row_Can_Copy;

   function Row_Can_Clear
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Can_Clear;
   end Row_Can_Clear;

   function Has_Clearable_Row
     (Panel : Feature_Panel_State) return Boolean
   is
   begin
      for I in 1 .. Row_Count (Panel) loop
         if Row_Can_Clear (Panel, I) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Clearable_Row;

   function Row_Can_Reveal
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Can_Reveal;
   end Row_Can_Reveal;

   function Row_Actions
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Row_Actions
   is
   begin
      if Index > Row_Count (Panel) then
         return (others => False);
      end if;
      return (Can_Select => Panel.Rows.Element (Index - 1).Selectable,
              Can_Open   => Panel.Rows.Element (Index - 1).Can_Open,
              Can_Copy   => Panel.Rows.Element (Index - 1).Can_Copy,
              Can_Clear  => Panel.Rows.Element (Index - 1).Can_Clear,
              Can_Reveal => Panel.Rows.Element (Index - 1).Can_Reveal);
   end Row_Actions;

   function Row_Source_Index
     (Panel : Feature_Panel_State;
      Index : Positive) return Natural
   is
   begin
      if Index > Row_Count (Panel) then
         return 0;
      end if;
      return Panel.Rows.Element (Index - 1).Source_Index;
   end Row_Source_Index;

   function Row_Severity
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Row_Severity
   is
   begin
      if Index > Row_Count (Panel) then
         return Feature_Row_No_Severity;
      end if;
      return Panel.Rows.Element (Index - 1).Severity;
   end Row_Severity;

   function Row_Count
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      return Natural (Panel.Rows.Length);
   end Row_Count;

   function Selected_Row
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      if Panel.Selected >= 1
        and then Panel.Selected <= Row_Count (Panel)
        and then Row_Is_Selectable (Panel, Positive (Panel.Selected))
      then
         return Panel.Selected;
      end if;
      return 0;
   end Selected_Row;

   function First_Selectable_Row
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      for I in 1 .. Row_Count (Panel) loop
         if Row_Is_Selectable (Panel, I) then
            return I;
         end if;
      end loop;
      return 0;
   end First_Selectable_Row;

   function Last_Selectable_Row
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      for I in reverse 1 .. Row_Count (Panel) loop
         if Row_Is_Selectable (Panel, I) then
            return I;
         end if;
      end loop;
      return 0;
   end Last_Selectable_Row;

   function Next_Selectable_Row
     (Panel : Feature_Panel_State;
      After : Natural) return Natural
   is
   begin
      if After >= Row_Count (Panel) then
         return 0;
      end if;
      for I in After + 1 .. Row_Count (Panel) loop
         if Row_Is_Selectable (Panel, I) then
            return I;
         end if;
      end loop;
      return 0;
   end Next_Selectable_Row;

   function Previous_Selectable_Row
     (Panel  : Feature_Panel_State;
      Before : Natural) return Natural
   is
   begin
      if Before <= 1 then
         return 0;
      end if;
      for I in reverse 1 .. Before - 1 loop
         if Row_Is_Selectable (Panel, I) then
            return I;
         end if;
      end loop;
      return 0;
   end Previous_Selectable_Row;

   procedure Reveal_Selected_Row
     (Panel : in out Feature_Panel_State)
   is
      Selected : constant Natural := Panel.Selected;
      Last_Visible : Natural;
   begin
      if Selected = 0 then
         Clamp_Selection (Panel);
         return;
      end if;

      Clamp_Selection (Panel);
      if Panel.Selected = 0 then
         return;
      end if;

      Last_Visible := Panel.First_Visible_Row + Panel.Visible_Row_Count - 1;
      if Panel.Selected < Panel.First_Visible_Row then
         Panel.First_Visible_Row := Panel.Selected;
      elsif Panel.Selected > Last_Visible then
         Panel.First_Visible_Row := Panel.Selected - Panel.Visible_Row_Count + 1;
      end if;
   end Reveal_Selected_Row;

   procedure Select_First
     (Panel : in out Feature_Panel_State)
   is
   begin
      Panel.Selected := First_Selectable_Row (Panel);
      Reveal_Selected_Row (Panel);
      Assert_Invariant (Panel, "Select_First");
   end Select_First;

   procedure Select_Row
     (Panel : in out Feature_Panel_State;
      Index : Natural)
   is
   begin
      if Index >= 1
        and then Index <= Row_Count (Panel)
        and then Row_Is_Selectable (Panel, Positive (Index))
      then
         Panel.Selected := Index;
      else
         Panel.Selected := 0;
      end if;
      Reveal_Selected_Row (Panel);
      Assert_Invariant (Panel, "Select_Row");
   end Select_Row;

   procedure Select_Next
     (Panel : in out Feature_Panel_State)
   is
      Count : constant Natural := Row_Count (Panel);
      Next  : Natural := 0;
   begin
      if Count = 0 then
         Panel.Selected := 0;
      elsif Selected_Row (Panel) = 0 then
         Panel.Selected := First_Selectable_Row (Panel);
      else
         Next := Next_Selectable_Row (Panel, Selected_Row (Panel));
         if Next /= 0 then
            Panel.Selected := Next;
         end if;
      end if;
      Reveal_Selected_Row (Panel);
      Assert_Invariant (Panel, "Select_Next");
   end Select_Next;

   procedure Select_Previous
     (Panel : in out Feature_Panel_State)
   is
      Previous : Natural := 0;
   begin
      if Row_Count (Panel) = 0 then
         Panel.Selected := 0;
      elsif Selected_Row (Panel) = 0 then
         Panel.Selected := Last_Selectable_Row (Panel);
      else
         Previous := Previous_Selectable_Row (Panel, Selected_Row (Panel));
         if Previous /= 0 then
            Panel.Selected := Previous;
         end if;
      end if;
      Reveal_Selected_Row (Panel);
      Assert_Invariant (Panel, "Select_Previous");
   end Select_Previous;

   function Has_Selection
     (Panel : Feature_Panel_State) return Boolean
   is
   begin
      return Selected_Row (Panel) /= 0;
   end Has_Selection;

   function Empty_Message
     (Panel : Feature_Panel_State) return String
   is
      pragma Unreferenced (Panel);
   begin
      return "No feature rows";
   end Empty_Message;

   function Row_Kind
     (Panel : Feature_Panel_State;
      Index : Positive) return Feature_Panel_Row_Kind
   is
   begin
      if Index > Row_Count (Panel) then
         return Feature_Row_Empty_State;
      end if;
      return Panel.Rows.Element (Index - 1).Kind;
   end Row_Kind;

   function Row_Label
     (Panel : Feature_Panel_State;
      Index : Positive) return String
   is
   begin
      if Index > Row_Count (Panel) then
         return "";
      end if;
      return To_String (Panel.Rows.Element (Index - 1).Label);
   end Row_Label;

   function Row_Detail
     (Panel : Feature_Panel_State;
      Index : Positive) return String
   is
   begin
      if Index > Row_Count (Panel) then
         return "";
      end if;
      return To_String (Panel.Rows.Element (Index - 1).Detail);
   end Row_Detail;

   function Row_Is_Current_Symbol
     (Panel : Feature_Panel_State;
      Index : Positive) return Boolean
   is
   begin
      if Index > Row_Count (Panel) then
         return False;
      end if;
      return Panel.Rows.Element (Index - 1).Is_Current_Symbol;
   end Row_Is_Current_Symbol;

   procedure Request_Reveal_Row
     (Panel : in out Feature_Panel_State;
      Index : Natural)
   is
   begin
      if Reveal_Row_Index_Is_Valid (Panel, Index) then
         Panel.Reveal_Row := Index;
      else
         Panel.Reveal_Row := 0;
      end if;
      Assert_Invariant (Panel, "Request_Reveal_Row");
   end Request_Reveal_Row;

   procedure Request_Reveal_Row
     (Panel : in out Feature_Panel_State;
      Token : Feature_Projection_Token;
      Index : Natural)
   is
   begin
      if Validate_Feature_Projection_Token (Panel, Token) then
         Request_Reveal_Row (Panel, Index);
      else
         Panel.Reveal_Row := 0;
         Assert_Invariant (Panel, "Request_Reveal_Row stale token");
      end if;
   end Request_Reveal_Row;

   function Requested_Reveal_Row
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      if Reveal_Row_Index_Is_Valid (Panel, Panel.Reveal_Row) then
         return Panel.Reveal_Row;
      end if;
      return 0;
   end Requested_Reveal_Row;

   procedure Clear_Reveal_Request
     (Panel : in out Feature_Panel_State)
   is
   begin
      Panel.Reveal_Row := 0;
      Assert_Invariant (Panel, "Clear_Reveal_Request");
   end Clear_Reveal_Request;

   procedure Set_Visible_Row_Count
     (Panel : in out Feature_Panel_State;
      Count : Natural)
   is
   begin
      Panel.Visible_Row_Count := Natural'Max (Count, 1);
      Clamp_Selection (Panel);
      Assert_Invariant (Panel, "Set_Visible_Row_Count");
   end Set_Visible_Row_Count;

   function Visible_Row_Count
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      return Panel.Visible_Row_Count;
   end Visible_Row_Count;

   function First_Visible_Row
     (Panel : Feature_Panel_State) return Natural
   is
   begin
      if Row_Count (Panel) = 0 then
         return 1;
      end if;
      return Panel.First_Visible_Row;
   end First_Visible_Row;

   function Visible_Row_To_Row_Index
     (Panel       : Feature_Panel_State;
      Visible_Row : Natural) return Natural
   is
      Row : Natural := 0;
   begin
      if Visible_Row = 0 or else Row_Count (Panel) = 0 then
         return 0;
      end if;

      if Visible_Row > Panel.Visible_Row_Count then
         return 0;
      end if;

      Row := Panel.First_Visible_Row + Visible_Row - 1;
      if Row > Row_Count (Panel) then
         return 0;
      end if;

      return Row;
   end Visible_Row_To_Row_Index;

   procedure Reveal_Row
     (Panel : in out Feature_Panel_State;
      Row   : Natural)
   is
      Last_Visible : Natural;
   begin
      if not Reveal_Row_Index_Is_Valid (Panel, Row) then
         Panel.Reveal_Row := 0;
         Assert_Invariant (Panel, "Reveal_Row invalid");
         return;
      end if;

      Clamp_Selection (Panel);
      Last_Visible := Panel.First_Visible_Row + Panel.Visible_Row_Count - 1;

      if Row < Panel.First_Visible_Row then
         Panel.First_Visible_Row := Row;
      elsif Row > Last_Visible then
         Panel.First_Visible_Row := Row - Panel.Visible_Row_Count + 1;
      end if;

      Assert_Invariant (Panel, "Reveal_Row");
   end Reveal_Row;

   procedure Clamp_Viewport
     (Panel : in out Feature_Panel_State)
   is
   begin
      Clamp_Selection (Panel);
      Assert_Invariant (Panel, "Clamp_Viewport");
   end Clamp_Viewport;

   procedure Scroll_By
     (Panel : in out Feature_Panel_State;
      Step_Delta : Integer)
   is
      Count    : constant Natural := Row_Count (Panel);
      Last_Top : Natural := 1;
      Desired  : Integer := Integer (Panel.First_Visible_Row) + Step_Delta;
   begin
      if Count = 0 then
         Panel.First_Visible_Row := 1;
         Assert_Invariant (Panel, "Scroll_By empty");
         return;
      end if;

      if Count > Panel.Visible_Row_Count then
         Last_Top := Count - Panel.Visible_Row_Count + 1;
      end if;

      if Desired < 1 then
         Desired := 1;
      elsif Desired > Integer (Last_Top) then
         Desired := Integer (Last_Top);
      end if;

      Panel.First_Visible_Row := Natural (Desired);
      Assert_Invariant (Panel, "Scroll_By");
   end Scroll_By;

   procedure Apply_Pending_Reveal
     (Panel : in out Feature_Panel_State)
   is
      Row : constant Natural := Requested_Reveal_Row (Panel);
   begin
      if Row = 0 then
         Clear_Reveal_Request (Panel);
      else
         Reveal_Row (Panel, Row);
         Clear_Reveal_Request (Panel);
      end if;
   end Apply_Pending_Reveal;

   function Build_Render_Snapshot
     (Panel : Feature_Panel_State) return Feature_Panel_Render_Snapshot
   is
      Snapshot : Feature_Panel_Render_Snapshot;
      Selected : constant Natural := Selected_Row (Panel);
   begin
      Snapshot.Visible := Panel.Visible;
      Snapshot.Focused := Panel.Focused and then Panel.Visible;
      Snapshot.Empty_Message := To_Unbounded_String (Empty_Message (Panel));
      Snapshot.Header := Panel.Header;
      Snapshot.Projection_Generation := Panel.Projection_Generation;
      Snapshot.Projection_Feature := Active_Feature (Panel);
      Snapshot.First_Visible_Row := Panel.First_Visible_Row;
      Snapshot.Visible_Row_Count := Panel.Visible_Row_Count;
      for I in 1 .. Row_Count (Panel) loop
         Snapshot.Rows.Append
           (To_Render_Row
              (Panel.Rows.Element (I - 1),
               Selected /= 0 and then I = Selected));
      end loop;
      return Snapshot;
   end Build_Render_Snapshot;

   function Snapshot_Is_Visible
     (Snapshot : Feature_Panel_Render_Snapshot) return Boolean
   is
   begin
      return Snapshot.Visible;
   end Snapshot_Is_Visible;

   function Snapshot_Is_Focused
     (Snapshot : Feature_Panel_Render_Snapshot) return Boolean
   is
   begin
      return Snapshot.Focused and then Snapshot.Visible;
   end Snapshot_Is_Focused;

   function Snapshot_Header_Text
     (Snapshot : Feature_Panel_Render_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Header);
   end Snapshot_Header_Text;

   function Snapshot_Projection_Generation
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural
   is
   begin
      return Snapshot.Projection_Generation;
   end Snapshot_Projection_Generation;

   function Snapshot_First_Visible_Row
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural
   is
   begin
      return Snapshot.First_Visible_Row;
   end Snapshot_First_Visible_Row;

   function Snapshot_Visible_Row_Count
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural
   is
   begin
      return Snapshot.Visible_Row_Count;
   end Snapshot_Visible_Row_Count;

   function Snapshot_Row_Count
     (Snapshot : Feature_Panel_Render_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Rows.Length);
   end Snapshot_Row_Count;

   function Snapshot_Empty_Message
     (Snapshot : Feature_Panel_Render_Snapshot) return String
   is
   begin
      return To_String (Snapshot.Empty_Message);
   end Snapshot_Empty_Message;

   function Snapshot_Row_Selected
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Selected;
   end Snapshot_Row_Selected;

   function Snapshot_Row_Is_Current_Symbol
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Is_Current_Symbol;
   end Snapshot_Row_Is_Current_Symbol;

   function Snapshot_Row_Label
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return String
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return "";
      end if;
      return To_String (Snapshot.Rows.Element (Index - 1).Label);
   end Snapshot_Row_Label;

   function Snapshot_Row_Detail
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return String
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return "";
      end if;
      return To_String (Snapshot.Rows.Element (Index - 1).Detail);
   end Snapshot_Row_Detail;

   function Snapshot_Row_Severity
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Feature_Row_Severity
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return Feature_Row_No_Severity;
      end if;
      return Snapshot.Rows.Element (Index - 1).Severity;
   end Snapshot_Row_Severity;

   function Snapshot_Row_Can_Open
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Can_Open;
   end Snapshot_Row_Can_Open;

   function Snapshot_Row_Can_Copy
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Can_Copy;
   end Snapshot_Row_Can_Copy;

   function Snapshot_Row_Can_Clear
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Can_Clear;
   end Snapshot_Row_Can_Clear;

   function Snapshot_Row_Can_Reveal
     (Snapshot : Feature_Panel_Render_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot_Row_Count (Snapshot) then
         return False;
      end if;
      return Snapshot.Rows.Element (Index - 1).Can_Reveal;
   end Snapshot_Row_Can_Reveal;


   function Message_Feature_Panel_Shown return String is
   begin
      return "Feature panel shown";
   end Message_Feature_Panel_Shown;

   function Message_Feature_Panel_Hidden return String is
   begin
      return "Feature panel hidden";
   end Message_Feature_Panel_Hidden;

   function Message_Feature_Panel_Focused return String is
   begin
      return "Feature panel focused";
   end Message_Feature_Panel_Focused;

   function Message_Feature_Panel_Cleared return String is
   begin
      return "Feature panel: active feature cleared";
   end Message_Feature_Panel_Cleared;

   function Message_Feature_Panel_Row_Has_No_Target return String is
   begin
      return "Feature panel: target unavailable";
   end Message_Feature_Panel_Row_Has_No_Target;

   function Reason_Feature_Panel_Hidden return String is
   begin
      return "Feature panel hidden";
   end Reason_Feature_Panel_Hidden;

   function Reason_Feature_Panel_Already_Shown return String is
   begin
      return "Feature panel already shown";
   end Reason_Feature_Panel_Already_Shown;

   function Reason_Feature_Panel_Already_Focused return String is
   begin
      return "Feature panel already focused";
   end Reason_Feature_Panel_Already_Focused;

   function Reason_No_Feature_Panel_Rows return String is
   begin
      return "Feature panel: no selectable row";
   end Reason_No_Feature_Panel_Rows;

   function Reason_No_Feature_Panel_Row_Selected return String is
   begin
      return "No feature panel row selected";
   end Reason_No_Feature_Panel_Row_Selected;

end Editor.Feature_Panel;
