with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;

package body Editor.Keybindings is

   use type Editor.Commands.Command_Id;

   type Binding_Entry is record
      Used  : Boolean := False;
      Chord : Key_Chord :=
        (Key => Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   end record;

   Max_Bindings : constant Natural := 256;
   subtype Binding_Index is Natural range 1 .. Max_Bindings;
   type Binding_Table is array (Binding_Index) of Binding_Entry;

   Bindings : Binding_Table;

   function Same_Chord (L, R : Key_Chord) return Boolean is
   begin
      return L.Key = R.Key
        and then L.Modifiers.Ctrl = R.Modifiers.Ctrl
        and then L.Modifiers.Shift = R.Modifiers.Shift
        and then L.Modifiers.Alt = R.Modifiers.Alt
        and then L.Modifiers.Meta = R.Modifiers.Meta;
   end Same_Chord;

   function Chord
     (Key   : Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False;
      Meta  : Boolean := False) return Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => Meta));
   end Chord;

   procedure Clear is
   begin
      for I in Bindings'Range loop
         Bindings (I).Used := False;
      end loop;
   end Clear;

   function Is_Normal_Assignable_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Is_Bindable_Command (Id)
        and then not Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id)
        and then not Editor.Commands.Is_Public_Build_Command (Id);
   end Is_Normal_Assignable_Command;

   function First_Free_Binding_Index (Found : out Boolean) return Natural is
   begin
      for I in Bindings'Range loop
         if not Bindings (I).Used then
            Found := True;
            return I;
         end if;
      end loop;
      Found := False;
      return Bindings'First;
   end First_Free_Binding_Index;

   procedure Bind
     (Chord : Key_Chord;
      Id    : Editor.Commands.Command_Id)
   is
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Same_Chord (Bindings (I).Chord, Chord) then
            Bindings (I).Id := Id;
            return;
         end if;
      end loop;

      for I in Bindings'Range loop
         if not Bindings (I).Used then
            Bindings (I) := (Used => True, Chord => Chord, Id => Id);
            return;
         end if;
      end loop;

      pragma Assert (False, "Editor.Keybindings binding table is full");
   end Bind;

   procedure Assign
     (Chord  : Key_Chord;
      Id     : Editor.Commands.Command_Id;
      Status : out Keybinding_Change_Status)
   is
      Free_Index : Natural := Bindings'First;
      Has_Free   : Boolean := False;
   begin
      if not Editor.Commands.Is_Concrete_Command (Id) then
         Status := Keybinding_Change_Invalid_Target;
         return;
      elsif Editor.Commands.Is_Public_Build_Command (Id) then
         Status := Keybinding_Change_Public_Build_Target;
         return;
      elsif Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id) then
         Status := Keybinding_Change_Internal_Target;
         return;
      elsif not Editor.Commands.Is_Bindable_Command (Id) then
         Status := Keybinding_Change_Non_Bindable_Target;
         return;
      end if;

      --  Preflight capacity before mutating. Reusing the existing command row
      --  or an existing chord row never requires a free slot.
      for I in Bindings'Range loop
         if Bindings (I).Used
           and then (Bindings (I).Id = Id
                     or else Same_Chord (Bindings (I).Chord, Chord))
         then
            Has_Free := True;
            exit;
         end if;
      end loop;

      if not Has_Free then
         Free_Index := First_Free_Binding_Index (Has_Free);
         if not Has_Free then
            Status := Keybinding_Change_Table_Full;
            return;
         end if;
      end if;

      --  Last-assignment-wins policy: one primary chord per command for normal
      --  editing, and the assigned chord has exactly one owner afterwards.
      for I in Bindings'Range loop
         if Bindings (I).Used
           and then (Bindings (I).Id = Id
                     or else Same_Chord (Bindings (I).Chord, Chord))
         then
            Bindings (I).Used := False;
         end if;
      end loop;

      Free_Index := First_Free_Binding_Index (Has_Free);
      if Has_Free then
         Bindings (Free_Index) := (Used => True, Chord => Chord, Id => Id);
         Status := Keybinding_Change_Ok;
      else
         --  Defensive fallback; the earlier preflight should make this
         --  unreachable while still preventing a misleading success status.
         Status := Keybinding_Change_Table_Full;
      end if;
   end Assign;

   procedure Unbind
     (Chord : Key_Chord)
   is
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Same_Chord (Bindings (I).Chord, Chord) then
            Bindings (I).Used := False;
            return;
         end if;
      end loop;
   end Unbind;

   procedure Unbind_Command
     (Id : Editor.Commands.Command_Id)
   is
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Bindings (I).Id = Id then
            Bindings (I).Used := False;
         end if;
      end loop;
   end Unbind_Command;

   function Can_Register_Default_Keybinding
     (Chord : Key_Chord) return Boolean
   is
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Same_Chord (Bindings (I).Chord, Chord) then
            return False;
         end if;
      end loop;
      return True;
   end Can_Register_Default_Keybinding;

   procedure Register_Default_If_Free
     (Result  : in out Default_Keybinding_Registration_Result;
      Chord   : Key_Chord;
      Command : Editor.Commands.Command_Id)
   is
   begin
      Result.Requested_Count := Result.Requested_Count + 1;
      if Can_Register_Default_Keybinding (Chord) then
         Bind (Chord, Command);
         Result.Registered_Count := Result.Registered_Count + 1;
      else
         Result.Conflict_Count := Result.Conflict_Count + 1;
      end if;
   end Register_Default_If_Free;

   function Register_Outline_Keybindings
      return Default_Keybinding_Registration_Result
   is
      Result : Default_Keybinding_Registration_Result;
   begin
      --  Conservative outline navigation defaults. They use Alt/Ctrl+Alt
      --  function-key chords so plain editor navigation, text editing, search,
      --  and command-palette keys remain untouched.
      Register_Default_If_Free
        (Result, Chord (Key_F12, Ctrl => True),
         Editor.Commands.Command_Refresh_Outline);
      Register_Default_If_Free
        (Result, Chord (Key_Enter, Alt => True),
         Editor.Commands.Command_Open_Selected_Outline_Item);
      Register_Default_If_Free
        (Result, Chord (Key_F3, Alt => True),
         Editor.Commands.Command_Select_Next_Outline_Item);
      Register_Default_If_Free
        (Result, Chord (Key_F3, Alt => True, Shift => True),
         Editor.Commands.Command_Select_Previous_Outline_Item);
      Register_Default_If_Free
        (Result, Chord (Key_F12, Alt => True),
         Editor.Commands.Command_Select_Current_Outline_Symbol);
      Register_Default_If_Free
        (Result, Chord (Key_F12, Alt => True, Shift => True),
         Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      return Result;
   end Register_Outline_Keybindings;

   function Register_Daily_Workflow_Keybindings
      return Default_Keybinding_Registration_Result
   is
      Result : Default_Keybinding_Registration_Result;
   begin
      --  Daily product-loop defaults intentionally use familiar chords where
      --  they do not conflict with text editing or existing core navigation.
      --  build.run remains unbound because it is explicit-consent gated.
      Register_Default_If_Free
        (Result, Chord (Key_F1),
         Editor.Commands.Command_Palette_Show_Command_Help);
      Register_Default_If_Free
        (Result, Chord (Key_O, Ctrl => True),
         Editor.Commands.Command_Open_File);
      Register_Default_If_Free
        (Result, Chord (Key_O, Ctrl => True, Alt => True),
         Editor.Commands.Command_Open_Project);
      Register_Default_If_Free
        (Result, Chord (Key_M, Ctrl => True, Alt => True),
         Editor.Commands.Command_Diagnostics_Show);
      return Result;
   end Register_Daily_Workflow_Keybindings;

   function Resolve
     (Chord : Key_Chord;
      Id    : out Editor.Commands.Command_Id) return Binding_Result
   is
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Same_Chord (Bindings (I).Chord, Chord) then
            --  Phase 404 hardening: low-level test/support Bind may still
            --  place non-bindable command ids in the table. Runtime resolution
            --  must not expose them to Input_Bridge as named user keybindings;
            --  validation reports invalid targets separately.
            if Editor.Commands.Is_Bindable_Command (Bindings (I).Id) then
               Id := Bindings (I).Id;
               return Bound_Command;
            else
               Id := Editor.Commands.No_Command;
               return No_Binding;
            end if;
         end if;
      end loop;

      Id := Editor.Commands.No_Command;
      return No_Binding;
   end Resolve;



   function Key_Name (Key : Key_Code) return String is
   begin
      case Key is
         when Key_Left      => return "Left";
         when Key_Right     => return "Right";
         when Key_Up        => return "Up";
         when Key_Down      => return "Down";
         when Key_Home      => return "Home";
         when Key_End       => return "End";
         when Key_Page_Up   => return "PageUp";
         when Key_Page_Down => return "PageDown";
         when Key_Backspace => return "Backspace";
         when Key_Delete    => return "Delete";
         when Key_Enter     => return "Enter";
         when Key_Escape    => return "Escape";
         when Key_A         => return "A";
         when Key_S         => return "S";
         when Key_C         => return "C";
         when Key_X         => return "X";
         when Key_V         => return "V";
         when Key_F         => return "F";
         when Key_G         => return "G";
         when Key_H         => return "H";
         when Key_O         => return "O";
         when Key_P         => return "P";
         when Key_N         => return "N";
         when Key_W         => return "W";
         when Key_M         => return "M";
         when Key_L         => return "L";
         when Key_F1        => return "F1";
         when Key_F2        => return "F2";
         when Key_F3        => return "F3";
         when Key_F12       => return "F12";
         when Key_Tab       => return "Tab";
         when Key_Z         => return "Z";
         when Key_Y         => return "Y";
      end case;
   end Key_Name;

   procedure Append_Part
     (Text : in out Unbounded_String;
      Part : String)
   is
   begin
      if Length (Text) > 0 then
         Append (Text, "+");
      end if;
      Append (Text, Part);
   end Append_Part;


   function Key_From_Name (Name : String; Found : out Boolean) return Key_Code is
      N : constant String := Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both));
   begin
      Found := True;
      if N = "left" then return Key_Left;
      elsif N = "right" then return Key_Right;
      elsif N = "up" then return Key_Up;
      elsif N = "down" then return Key_Down;
      elsif N = "home" then return Key_Home;
      elsif N = "end" then return Key_End;
      elsif N = "pageup" or else N = "page-up" then return Key_Page_Up;
      elsif N = "pagedown" or else N = "page-down" then return Key_Page_Down;
      elsif N = "backspace" then return Key_Backspace;
      elsif N = "delete" then return Key_Delete;
      elsif N = "enter" then return Key_Enter;
      elsif N = "escape" then return Key_Escape;
      elsif N = "a" then return Key_A;
      elsif N = "s" then return Key_S;
      elsif N = "c" then return Key_C;
      elsif N = "x" then return Key_X;
      elsif N = "v" then return Key_V;
      elsif N = "f" then return Key_F;
      elsif N = "g" then return Key_G;
      elsif N = "h" then return Key_H;
      elsif N = "o" then return Key_O;
      elsif N = "p" then return Key_P;
      elsif N = "n" then return Key_N;
      elsif N = "w" then return Key_W;
      elsif N = "m" then return Key_M;
      elsif N = "l" then return Key_L;
      elsif N = "f1" then return Key_F1;
      elsif N = "f2" then return Key_F2;
      elsif N = "f3" then return Key_F3;
      elsif N = "f12" then return Key_F12;
      elsif N = "tab" then return Key_Tab;
      elsif N = "z" then return Key_Z;
      elsif N = "y" then return Key_Y;
      else
         Found := False;
         return Key_Left;
      end if;
   end Key_From_Name;

   function Is_Text_Key (Key : Key_Code) return Boolean is
   begin
      case Key is
         when Key_A | Key_S | Key_C | Key_X | Key_V | Key_F | Key_G | Key_H
            | Key_O | Key_P | Key_N | Key_W | Key_M | Key_L | Key_Z | Key_Y =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Key;

   function Has_Any_Modifier (Modifiers : Modifier_Set) return Boolean is
   begin
      return Modifiers.Ctrl or else Modifiers.Alt
        or else Modifiers.Shift or else Modifiers.Meta;
   end Has_Any_Modifier;

   function Parse_Chord
     (Text  : String;
      Found : out Boolean) return Key_Chord
   is
      T      : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
      Start  : Positive := T'First;
      Result : Key_Chord :=
        (Key => Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Have_Key : Boolean := False;
      Part_Ok  : Boolean := False;
      K        : Key_Code;
   begin
      if T'Length = 0 then
         Found := False;
         return Result;
      end if;

      for I in T'First .. T'Last + 1 loop
         if I = T'Last + 1 or else T (I) = '+' then
            declare
               Part : constant String := Ada.Strings.Fixed.Trim (T (Start .. I - 1), Ada.Strings.Both);
               Low  : constant String := Ada.Characters.Handling.To_Lower (Part);
            begin
               if Part'Length = 0 or else Have_Key then
                  Found := False;
                  return Result;
               elsif Low = "ctrl" then
                  if Result.Modifiers.Ctrl then Found := False; return Result; end if;
                  Result.Modifiers.Ctrl := True;
               elsif Low = "alt" then
                  if Result.Modifiers.Alt then Found := False; return Result; end if;
                  Result.Modifiers.Alt := True;
               elsif Low = "shift" then
                  if Result.Modifiers.Shift then Found := False; return Result; end if;
                  Result.Modifiers.Shift := True;
               elsif Low = "meta" then
                  if Result.Modifiers.Meta then Found := False; return Result; end if;
                  Result.Modifiers.Meta := True;
               else
                  K := Key_From_Name (Part, Part_Ok);
                  if not Part_Ok then
                     Found := False;
                     return Result;
                  end if;
                  Result.Key := K;
                  Have_Key := True;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;

      if Have_Key
        and then Is_Text_Key (Result.Key)
        and then not Has_Any_Modifier (Result.Modifiers)
      then
         Found := False;
         return Result;
      end if;

      Found := Have_Key;
      return Result;
   end Parse_Chord;

   function Format_Chord
     (Chord : Key_Chord) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Chord.Modifiers.Ctrl then
         Append_Part (Result, "Ctrl");
      end if;
      if Chord.Modifiers.Alt then
         Append_Part (Result, "Alt");
      end if;
      if Chord.Modifiers.Shift then
         Append_Part (Result, "Shift");
      end if;
      if Chord.Modifiers.Meta then
         Append_Part (Result, "Meta");
      end if;
      Append_Part (Result, Key_Name (Chord.Key));
      return To_String (Result);
   end Format_Chord;

   function Binding_Count_For_Command
     (Command : Editor.Commands.Command_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Bindings (I).Id = Command then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Binding_Count_For_Command;

   function Binding_For_Command
     (Command : Editor.Commands.Command_Id;
      Index   : Positive) return Key_Chord
   is
      Count : Natural := 0;
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used and then Bindings (I).Id = Command then
            Count := Count + 1;
            if Count = Index then
               return Bindings (I).Chord;
            end if;
         end if;
      end loop;

      pragma Assert (False, "Editor.Keybindings.Binding_For_Command index out of range");
      return (Key => Key_Left,
              Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
   end Binding_For_Command;

   function Command_Name_Less
     (Left, Right : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Stable_Command_Name (Left)
        < Editor.Commands.Stable_Command_Name (Right);
   end Command_Name_Less;

   function Has_Any_Binding
     (Command : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Binding_Count_For_Command (Command) > 0;
   end Has_Any_Binding;

   function Display_Command_At
     (Index         : Positive;
      Want_Bound     : Boolean;
      Want_Unbound   : Boolean;
      Assignable_Only : Boolean) return Editor.Commands.Command_Id
   is
      Best     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Best_Set : Boolean := False;
      Seen     : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Wanted   : Natural := 0;
      Eligible : Boolean;
      pragma Unreferenced (Assignable_Only);
   begin
      loop
         Best_Set := False;
         for Id in Editor.Commands.Command_Id loop
            Eligible := Id /= Editor.Commands.No_Command
              and then not Seen (Id)
              and then Is_Normal_Assignable_Command (Id)
              and then ((Want_Bound and then Has_Any_Binding (Id))
                        or else (Want_Unbound and then not Has_Any_Binding (Id)));
            if Eligible
              and then (not Best_Set or else Command_Name_Less (Id, Best))
            then
               Best := Id;
               Best_Set := True;
            end if;
         end loop;

         exit when not Best_Set;
         Seen (Best) := True;
         Wanted := Wanted + 1;
         if Wanted = Index then
            return Best;
         end if;
      end loop;

      pragma Assert (False, "Editor.Keybindings display command index out of range");
      return Editor.Commands.No_Command;
   end Display_Command_At;

   function Bound_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for Id in Editor.Commands.Command_Id loop
         if Is_Normal_Assignable_Command (Id)
           and then Has_Any_Binding (Id)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Bound_Command_Count;

   function Bound_Command_At
     (Index : Positive) return Editor.Commands.Command_Id
   is
   begin
      return Display_Command_At
        (Index, Want_Bound => True, Want_Unbound => False,
         Assignable_Only => False);
   end Bound_Command_At;

   function Unbound_Assignable_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for Id in Editor.Commands.Command_Id loop
         if Is_Normal_Assignable_Command (Id)
           and then not Has_Any_Binding (Id)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Unbound_Assignable_Command_Count;

   function Unbound_Assignable_Command_At
     (Index : Positive) return Editor.Commands.Command_Id
   is
   begin
      return Display_Command_At
        (Index, Want_Bound => False, Want_Unbound => True,
         Assignable_Only => True);
   end Unbound_Assignable_Command_At;

   function Primary_Binding_For_Command
     (Command : Editor.Commands.Command_Id) return Command_Keybinding_Info
   is
   begin
      for I in reverse Bindings'Range loop
         if Bindings (I).Used and then Bindings (I).Id = Command then
            return
              (Has_Binding => True,
               Display     => To_Unbounded_String (Format_Chord (Bindings (I).Chord)));
         end if;
      end loop;

      return
        (Has_Binding => False,
         Display     => Null_Unbounded_String);
   end Primary_Binding_For_Command;

   function Validate return Keybinding_Validation_Result
   is
      Result : Keybinding_Validation_Result;
      Resolved : Editor.Commands.Command_Id;
      Command_Bound : array (Editor.Commands.Command_Id) of Boolean := (others => False);
   begin
      for I in Bindings'Range loop
         if Bindings (I).Used then
            if Editor.Commands.Is_Bindable_Command (Bindings (I).Id) then
               Command_Bound (Bindings (I).Id) := True;
            else
               Result.Invalid_Targets := True;
               Result.Validation_Summary.Invalid_Count :=
                 Result.Validation_Summary.Invalid_Count + 1;
            end if;

            if Resolve (Bindings (I).Chord, Resolved) /= Bound_Command
              or else Resolved /= Bindings (I).Id
            then
               Result.Invalid_Targets := True;
               Result.Validation_Summary.Invalid_Count :=
                 Result.Validation_Summary.Invalid_Count + 1;
            end if;

            for J in I + 1 .. Bindings'Last loop
               if Bindings (J).Used
                 and then Same_Chord (Bindings (I).Chord, Bindings (J).Chord)
               then
                  Result.Duplicate_Chords := True;
                  Result.Validation_Summary.Conflict_Count :=
                    Result.Validation_Summary.Conflict_Count + 1;
               end if;
            end loop;
         end if;
      end loop;

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Is_Bindable_Command (Id) then
            if Command_Bound (Id) then
               Result.Validation_Summary.Bound_Command_Count :=
                 Result.Validation_Summary.Bound_Command_Count + 1;
            else
               Result.Validation_Summary.Unbound_Count :=
                 Result.Validation_Summary.Unbound_Count + 1;
            end if;
         end if;
      end loop;

      if Result.Invalid_Targets or else Result.Duplicate_Chords then
         Result.Validation_Status := Invalid_Keybindings;
      else
         Result.Validation_Status := Valid_Keybindings;
      end if;

      return Result;
   end Validate;

   function Status
     (Result : Keybinding_Validation_Result)
      return Keybinding_Validation_Status
   is
   begin
      return Result.Validation_Status;
   end Status;

   function Has_Invalid_Command_Targets
     (Result : Keybinding_Validation_Result) return Boolean
   is
   begin
      return Result.Invalid_Targets;
   end Has_Invalid_Command_Targets;

   function Has_Duplicate_Chords
     (Result : Keybinding_Validation_Result) return Boolean
   is
   begin
      return Result.Duplicate_Chords;
   end Has_Duplicate_Chords;

   function Summary
     (Result : Keybinding_Validation_Result)
      return Keybinding_Validation_Summary
   is
   begin
      return Result.Validation_Summary;
   end Summary;

   procedure Reset_To_Defaults is
   begin
      Clear;

      Bind (Chord (Key_S, Ctrl => True), Editor.Commands.Command_Save_File);
      Bind (Chord (Key_S, Ctrl => True, Shift => True),
            Editor.Commands.Command_Save_File_As);
      Bind (Chord (Key_F, Ctrl => True), Editor.Commands.Command_Find_Show);
      Bind (Chord (Key_G, Ctrl => True), Editor.Commands.Command_Goto_Line);
      Bind (Chord (Key_F, Ctrl => True, Shift => True), Editor.Commands.Command_Open_Project_Search_Bar);
      Bind (Chord (Key_P, Ctrl => True), Editor.Commands.Command_Open_Quick_Open);
      Bind (Chord (Key_P, Ctrl => True, Shift => True), Editor.Commands.Command_Open_Command_Palette);
      Bind (Chord (Key_N, Ctrl => True), Editor.Commands.Command_New_Buffer);
      Bind (Chord (Key_W, Ctrl => True), Editor.Commands.Command_Close_Active_Buffer);
      Bind (Chord (Key_M, Ctrl => True, Shift => True), Editor.Commands.Command_Toggle_Problems_Panel);
      Bind (Chord (Key_L, Ctrl => True), Editor.Commands.Command_Select_Line);
      Bind (Chord (Key_A, Ctrl => True), Editor.Commands.Command_Select_All);
      Bind (Chord (Key_C, Ctrl => True), Editor.Commands.Command_Copy);
      Bind (Chord (Key_X, Ctrl => True), Editor.Commands.Command_Cut);
      Bind (Chord (Key_V, Ctrl => True), Editor.Commands.Command_Paste);

      --  Phase 62 bookmark workflow bindings.  Function keys are represented
      --  explicitly so the runtime, bridge, resolver, and tests share the same
      --  command path.
      Bind (Chord (Key_F2), Editor.Commands.Command_Next_Bookmark);
      Bind (Chord (Key_F2, Shift => True), Editor.Commands.Command_Previous_Bookmark);
      Bind (Chord (Key_F2, Ctrl => True), Editor.Commands.Command_Toggle_Bookmark);
      Bind (Chord (Key_F2, Ctrl => True, Shift => True), Editor.Commands.Command_Clear_Bookmarks);

      --  Phase 70 search navigation bindings.
      Bind (Chord (Key_F3), Editor.Commands.Command_Active_Find_Next);
      Bind (Chord (Key_F3, Shift => True), Editor.Commands.Command_Active_Find_Previous);

      Bind (Chord (Key_Tab, Ctrl => True), Editor.Commands.Command_Previous_Recent_Buffer);
      Bind (Chord (Key_Tab, Ctrl => True, Shift => True), Editor.Commands.Command_Next_Recent_Buffer);
      Bind (Chord (Key_Z, Ctrl => True), Editor.Commands.Command_Undo);
      Bind (Chord (Key_Y, Ctrl => True), Editor.Commands.Command_Redo);
      Bind (Chord (Key_Z, Ctrl => True, Shift => True), Editor.Commands.Command_Redo);

      Bind (Chord (Key_Left, Alt => True), Editor.Commands.Command_Navigation_Back);
      Bind (Chord (Key_Right, Alt => True), Editor.Commands.Command_Navigation_Forward);

      Bind (Chord (Key_Left), Editor.Commands.Command_Move_Left);
      Bind (Chord (Key_Right), Editor.Commands.Command_Move_Right);
      Bind (Chord (Key_Up), Editor.Commands.Command_Move_Up);
      Bind (Chord (Key_Down), Editor.Commands.Command_Move_Down);
      Bind (Chord (Key_Home), Editor.Commands.Command_Move_Line_Start);
      Bind (Chord (Key_End), Editor.Commands.Command_Move_Line_End);
      Bind (Chord (Key_Home, Ctrl => True), Editor.Commands.Command_Move_Document_Start);
      Bind (Chord (Key_End, Ctrl => True), Editor.Commands.Command_Move_Document_End);
      Bind (Chord (Key_Left, Ctrl => True), Editor.Commands.Command_Move_Word_Left);
      Bind (Chord (Key_Right, Ctrl => True), Editor.Commands.Command_Move_Word_Right);
      Bind (Chord (Key_Backspace, Ctrl => True), Editor.Commands.Command_Word_Delete_Previous);
      Bind (Chord (Key_Delete, Ctrl => True), Editor.Commands.Command_Word_Delete_Next);
      Bind (Chord (Key_Page_Up), Editor.Commands.Command_Page_Up);
      Bind (Chord (Key_Page_Down), Editor.Commands.Command_Page_Down);
      Bind (Chord (Key_Page_Up, Shift => True), Editor.Commands.Command_Select_Page_Up);
      Bind (Chord (Key_Page_Down, Shift => True), Editor.Commands.Command_Select_Page_Down);
      --  Phase 408: the editor Backspace/Delete defaults target the canonical
      --  Character Delete command surface.  Overlay-local Backspace/Delete
      --  handling remains local to those overlays, but editor text deletion now
      --  enters through Executor as edit.char.delete-previous/next.
      Bind (Chord (Key_Backspace), Editor.Commands.Command_Char_Delete_Previous);
      Bind (Chord (Key_Delete), Editor.Commands.Command_Char_Delete_Next);
      Bind (Chord (Key_Enter), Editor.Commands.Command_Insert_Newline);
      Bind (Chord (Key_Escape), Editor.Commands.Command_Cancel);

      Bind (Chord (Key_Left, Shift => True), Editor.Commands.Command_Select_Left);
      Bind (Chord (Key_Right, Shift => True), Editor.Commands.Command_Select_Right);
      Bind (Chord (Key_Up, Shift => True), Editor.Commands.Command_Select_Up);
      Bind (Chord (Key_Down, Shift => True), Editor.Commands.Command_Select_Down);
      Bind (Chord (Key_Home, Shift => True), Editor.Commands.Command_Select_Line_Start);
      Bind (Chord (Key_End, Shift => True), Editor.Commands.Command_Select_Line_End);
      Bind (Chord (Key_Home, Ctrl => True, Shift => True), Editor.Commands.Command_Select_Document_Start);
      Bind (Chord (Key_End, Ctrl => True, Shift => True), Editor.Commands.Command_Select_Document_End);
      Bind (Chord (Key_Left, Ctrl => True, Shift => True), Editor.Commands.Command_Select_Word_Left);
      Bind (Chord (Key_Right, Ctrl => True, Shift => True), Editor.Commands.Command_Select_Word_Right);

      declare
         Registered : constant Default_Keybinding_Registration_Result :=
           Register_Daily_Workflow_Keybindings;
      begin
         pragma Assert
           (Registered.Registered_Count + Registered.Conflict_Count =
              Registered.Requested_Count,
            "daily workflow keybinding default registration accounting mismatch");
      end;

      declare
         Registered : constant Default_Keybinding_Registration_Result :=
           Register_Outline_Keybindings;
      begin
         pragma Assert
           (Registered.Registered_Count + Registered.Conflict_Count =
              Registered.Requested_Count,
            "outline keybinding default registration accounting mismatch");
      end;
   end Reset_To_Defaults;

begin
   Reset_To_Defaults;
end Editor.Keybindings;
