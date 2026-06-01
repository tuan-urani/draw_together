revoke execute on function public.list_joinable_rooms(public.room_mode) from public;
revoke execute on function public.list_joinable_rooms(public.room_mode) from anon;
grant execute on function public.list_joinable_rooms(public.room_mode) to authenticated;

revoke execute on function public.join_room(uuid) from public;
revoke execute on function public.join_room(uuid) from anon;
grant execute on function public.join_room(uuid) to authenticated;
