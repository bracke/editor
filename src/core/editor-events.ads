package Editor.Events is

   type Event_Type is (
      Key_Press
   );

   type Event is record
      Kind : Event_Type;
      Key  : Character;
   end record;

end Editor.Events;