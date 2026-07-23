package body Editor.Ada_Expression_Types.Model_Accessors is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Has_Expression_Types (Model : Expression_Type_Model) return Boolean is
   begin
      return not Model.Expressions.Is_Empty;
   end Has_Expression_Types;

   function Expression_Type_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Natural (Model.Expressions.Length);
   end Expression_Type_Count;

   function Expression_Type_At
     (Model : Expression_Type_Model;
      Index : Positive) return Expression_Type_Info is
   begin
      if Index > Natural (Model.Expressions.Length) then
         return (others => <>);
      end if;
      return Model.Expressions.Element (Index);
   end Expression_Type_At;

   function Expression_Type
     (Model : Expression_Type_Model;
      Id    : Expression_Type_Id) return Expression_Type_Info is
   begin
      if Id = No_Expression_Type or else Natural (Id) > Natural (Model.Expressions.Length) then
         return (others => <>);
      end if;
      return Model.Expressions.Element (Positive (Id));
   end Expression_Type;

   function Expression_Type_For_Node
     (Model : Expression_Type_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Type_Info is
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         declare
            Info : constant Expression_Type_Info := Model.Expressions.Element (Positive (I));
         begin
            if Info.Node = Node then
               return Info;
            end if;
         end;
      end loop;
      return (others => <>);
   end Expression_Type_For_Node;

   function Count_Status
     (Model  : Expression_Type_Model;
      Status : Expression_Type_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

end Editor.Ada_Expression_Types.Model_Accessors;
