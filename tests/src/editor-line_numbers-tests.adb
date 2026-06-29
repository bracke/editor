with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Interfaces.C;
with Editor.Commands;
with Editor.Command_Palette;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Render_Layers;
with Editor.Render_Packet;
with Editor.Settings;
with Editor.State;
with Editor.View;
with Editor.Scrollbars;
with Editor.Folding;
use type Editor.Commands.Command_Id;
use type Editor.Line_Numbers.Line_Number_Mode;
use type Interfaces.C.int;

package body Editor.Line_Numbers.Tests is

   overriding function Name
     (T : Line_Numbers_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Line_Numbers");
   end Name;

   function Count_Gutter_Text_Glyphs
     (Packet : Editor.Render_Packet.Render_Packet) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 0 .. Natural (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (Natural (I)).Layer =
           Editor.Render_Layers.To_C (Editor.Render_Layers.Gutter_Text_Layer)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Gutter_Text_Glyphs;

   procedure Prepare_Text
     (Text : String)
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Settings.Reset;
      Editor.Line_Numbers.Reset;
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (800, 160);
      Editor.Scrollbars.Reset;
   end Prepare_Text;

   procedure Test_Absolute_Mode_Displays_One_Based_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Line_Number_Config :=
        (Mode => Absolute_Line_Numbers);
   begin
      Assert
        (Display_Text (Config, Document_Row => 0, Current_Row => 3) = "1",
         "Absolute mode must display one-based document row numbers");
      Assert
        (Display_Text (Config, Document_Row => 41, Current_Row => 3) = "42",
         "Absolute mode must not depend on the caret row");
   end Test_Absolute_Mode_Displays_One_Based_Row;

   procedure Test_Relative_Mode_Displays_Zero_On_Current_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Line_Number_Config :=
        (Mode => Relative_Line_Numbers);
   begin
      Assert
        (Display_Text (Config, Document_Row => 7, Current_Row => 7) = "0",
         "Relative mode must display zero on the primary caret row");
   end Test_Relative_Mode_Displays_Zero_On_Current_Row;

   procedure Test_Relative_Mode_Displays_Row_Distance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Line_Number_Config :=
        (Mode => Relative_Line_Numbers);
   begin
      Assert
        (Display_Text (Config, Document_Row => 2, Current_Row => 7) = "5",
         "Relative mode must display upward document-row distance");
      Assert
        (Display_Text (Config, Document_Row => 10, Current_Row => 7) = "3",
         "Relative mode must display downward document-row distance");
   end Test_Relative_Mode_Displays_Row_Distance;

   procedure Test_Hybrid_Mode_Displays_Absolute_Current_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Line_Number_Config :=
        (Mode => Hybrid_Line_Numbers);
   begin
      Assert
        (Display_Text (Config, Document_Row => 7, Current_Row => 7) = "8",
         "Hybrid mode must display the current row as an absolute one-based line number");
   end Test_Hybrid_Mode_Displays_Absolute_Current_Row;

   procedure Test_Hybrid_Mode_Displays_Relative_Other_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Line_Number_Config :=
        (Mode => Hybrid_Line_Numbers);
   begin
      Assert
        (Display_Text (Config, Document_Row => 5, Current_Row => 7) = "2",
         "Hybrid mode must display non-current rows as document-row distances");
      Assert
        (Display_Text (Config, Document_Row => 11, Current_Row => 7) = "4",
         "Hybrid mode must display non-current rows below the caret as distances");
   end Test_Hybrid_Mode_Displays_Relative_Other_Rows;

   procedure Test_Gutter_Width_Remains_Stable_Across_Modes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Widths : array (Line_Number_Mode) of Natural;
   begin
      for Mode in Line_Number_Mode loop
         Editor.Line_Numbers.Set_Current ((Mode => Mode));
         Widths (Mode) :=
           Editor.Layout.Gutter_Width_For_Line_Count (Layout, 1234);
      end loop;

      Assert
        (Widths (Absolute_Line_Numbers) = Widths (Relative_Line_Numbers)
         and then Widths (Relative_Line_Numbers) = Widths (Hybrid_Line_Numbers),
         "Gutter width must stay based on total line-count digits across modes");
   end Test_Gutter_Width_Remains_Stable_Across_Modes;

   procedure Test_Render_Packet_Emits_Gutter_Line_Number_Glyphs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Prepare_Text ("a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Count_Gutter_Text_Glyphs (Packet) > 0,
         "Render packet must emit line-number glyphs on the gutter text layer");
   end Test_Render_Packet_Emits_Gutter_Line_Number_Glyphs;

   procedure Test_Render_Packet_Keeps_Line_Numbers_Inside_Gutter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Packet : Editor.Render_Packet.Render_Packet;
      Seen   : Boolean := False;
      Left   : constant Float :=
        Float
          (Editor.Layout.Gutter_Fold_X (Layout)
           + Editor.Layout.Gutter_Fold_Width);
      Right  : constant Float :=
        Editor.Layout.Line_Number_Right_Edge (Layout, 123);
   begin
      Prepare_Text ("a" & ASCII.LF & "b" & ASCII.LF & "c");
      Editor.Input_Bridge.Build_Render_Packet (Packet);

      for I in 0 .. Natural (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (Natural (I)).Layer =
           Editor.Render_Layers.To_C (Editor.Render_Layers.Gutter_Text_Layer)
         then
            Seen := True;
            Assert
              (Float (Packet.Glyphs (Natural (I)).X) >= Left,
               "line-number glyph must not render before the line-number zone");
            Assert
              (Float (Packet.Glyphs (Natural (I)).X)
                 + Float (Packet.Glyphs (Natural (I)).W) <= Right,
               "line-number glyph must stay inside the gutter line-number column");
         end if;
      end loop;

      Assert (Seen, "test must observe at least one gutter line-number glyph");
   end Test_Render_Packet_Keeps_Line_Numbers_Inside_Gutter;

   procedure Test_Folded_Hidden_Rows_Emit_No_Line_Numbers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "a" & ASCII.LF & "b" & ASCII.LF & "c" & ASCII.LF & "d");
      Editor.Folding.Add_Fold (S.Folding, 1, 2);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Settings.Reset;
      Editor.Line_Numbers.Reset;
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (800, 160);
      Editor.Scrollbars.Reset;

      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert
        (Count_Gutter_Text_Glyphs (Packet) = 3,
         "Collapsed fold must emit line numbers only for visible document rows");
   end Test_Folded_Hidden_Rows_Emit_No_Line_Numbers;

   procedure Test_Toggle_Mode_Cycles_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.Line_Numbers.Set_Current
        ((Mode => Editor.Line_Numbers.Absolute_Line_Numbers));
      Editor.Line_Numbers.Toggle_Mode;
      Assert
        (Editor.Line_Numbers.Current.Mode = Editor.Line_Numbers.Relative_Line_Numbers,
         "First toggle must select relative line numbers");
      Editor.Line_Numbers.Toggle_Mode;
      Assert
        (Editor.Line_Numbers.Current.Mode = Editor.Line_Numbers.Hybrid_Line_Numbers,
         "Second toggle must select hybrid line numbers");
      Editor.Line_Numbers.Toggle_Mode;
      Assert
        (Editor.Line_Numbers.Current.Mode = Editor.Line_Numbers.Absolute_Line_Numbers,
         "Third toggle must return to absolute line numbers");
   end Test_Toggle_Mode_Cycles_Deterministically;


   procedure Test_Reset_Restores_Absolute_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.Line_Numbers.Set_Current
        ((Mode => Editor.Line_Numbers.Hybrid_Line_Numbers));
      Editor.Line_Numbers.Reset;
      Assert
        (Editor.Line_Numbers.Current.Mode = Editor.Line_Numbers.Absolute_Line_Numbers,
         "Reset must restore absolute line numbers");
   end Test_Reset_Restores_Absolute_Mode;

   procedure Test_Command_Palette_Exposes_Line_Number_Mode_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Descs : Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
      Seen_Toggle   : Boolean := False;
      Seen_Absolute : Boolean := False;
      Seen_Relative : Boolean := False;
      Seen_Hybrid   : Boolean := False;
   begin
      for Desc of Descs loop
         case Desc.Id is
            when Editor.Commands.Command_Toggle_Line_Number_Mode =>
               Seen_Toggle := True;
            when Editor.Commands.Command_Set_Absolute_Line_Numbers =>
               Seen_Absolute := True;
            when Editor.Commands.Command_Set_Relative_Line_Numbers =>
               Seen_Relative := True;
            when Editor.Commands.Command_Set_Hybrid_Line_Numbers =>
               Seen_Hybrid := True;
            when others =>
               null;
         end case;
      end loop;

      Assert
        (Seen_Toggle,
         "Command palette must expose the line-number mode toggle command");
      Assert
        (Seen_Absolute and then Seen_Relative and then Seen_Hybrid,
         "Command palette must expose explicit line-number mode commands");
   end Test_Command_Palette_Exposes_Line_Number_Mode_Command;

   overriding procedure Register_Tests
     (T : in out Line_Numbers_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Absolute_Mode_Displays_One_Based_Row'Access,
         "Absolute Mode Displays One Based Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Relative_Mode_Displays_Zero_On_Current_Row'Access,
         "Relative Mode Displays Zero On Current Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Relative_Mode_Displays_Row_Distance'Access,
         "Relative Mode Displays Row Distance");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hybrid_Mode_Displays_Absolute_Current_Row'Access,
         "Hybrid Mode Displays Absolute Current Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hybrid_Mode_Displays_Relative_Other_Rows'Access,
         "Hybrid Mode Displays Relative Other Rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Gutter_Width_Remains_Stable_Across_Modes'Access,
         "Gutter Width Remains Stable Across Modes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Emits_Gutter_Line_Number_Glyphs'Access,
         "Render Packet Emits Gutter Line Number Glyphs");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_Keeps_Line_Numbers_Inside_Gutter'Access,
         "Render Packet Keeps Line Numbers Inside Gutter");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Folded_Hidden_Rows_Emit_No_Line_Numbers'Access,
         "Folded Hidden Rows Emit No Line Numbers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Toggle_Mode_Cycles_Deterministically'Access,
         "Toggle Mode Cycles Deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reset_Restores_Absolute_Mode'Access,
         "Reset Restores Absolute Mode");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Exposes_Line_Number_Mode_Command'Access,
         "Command Palette Exposes Line Number Mode Command");
   end Register_Tests;

end Editor.Line_Numbers.Tests;
