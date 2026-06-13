with Editor.Buffers;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Recent_Buffers;

package Editor.Quick_Open_Markers is

   function Build_Snapshot
     (State    : Editor.Quick_Open.Quick_Open_State;
      Registry : Editor.Buffers.Buffer_Registry)
      return Editor.Quick_Open.Quick_Open_Snapshot;

   function Build_Snapshot
     (State    : Editor.Quick_Open.Quick_Open_State;
      Project  : Editor.Project.Project_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State)
      return Editor.Quick_Open.Quick_Open_Snapshot;

end Editor.Quick_Open_Markers;
