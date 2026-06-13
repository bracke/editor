package body Editor.Wrap is

   function Wrap_Column
     (Viewport_Text_Width : Natural;
      Cell_W              : Positive) return Positive
   is
      Cells : constant Natural := Viewport_Text_Width / Cell_W;
   begin
      return Positive'Max (1, Positive (Natural'Max (Cells, 1)));
   end Wrap_Column;

   function Visual_Row_Count_For_Logical_Line
     (Line_Length : Natural;
      Wrap_Col    : Positive) return Positive
   is
   begin
      if Line_Length = 0 then
         return 1;
      else
         return Positive ((Line_Length + Natural (Wrap_Col) - 1) / Natural (Wrap_Col));
      end if;
   end Visual_Row_Count_For_Logical_Line;

   function Visual_Row_For
     (Logical_Row : Natural;
      Logical_Col : Natural;
      Wrap_Col    : Positive) return Natural
   is
      pragma Unreferenced (Logical_Row);
   begin
      return Logical_Col / Natural (Wrap_Col);
   end Visual_Row_For;

   function Visual_Segment
     (Logical_Row : Natural;
      Visual_Part : Natural;
      Line_Length : Natural;
      Wrap_Col    : Positive) return Visual_Row_Info
   is
      Start_Col : constant Natural := Visual_Part * Natural (Wrap_Col);
      End_Col   : Natural := Natural'Min (Line_Length, Start_Col + Natural (Wrap_Col));
   begin
      if Start_Col > Line_Length then
         End_Col := Line_Length;
      end if;

      return
        (Logical_Row => Logical_Row,
         Start_Col   => Natural'Min (Start_Col, Line_Length),
         End_Col     => End_Col);
   end Visual_Segment;

end Editor.Wrap;
