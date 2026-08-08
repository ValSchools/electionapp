import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
serve(async req=>{
 if(req.method==='OPTIONS') return new Response('ok',{headers:cors});
  try{
   const supabaseUrl=Deno.env.get('SUPABASE_URL');
   const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
   if(!supabaseUrl||!serviceKey) throw new Error('Server misconfiguration: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set as Edge Function secrets.');
   const service=createClient(supabaseUrl,serviceKey);
   const token=(req.headers.get('Authorization')||'').replace('Bearer ','');
   if(!token) throw new Error('Missing Authorization header (admin session token required).');
   const {data:{user},error:who}=await service.auth.getUser(token);
   if(who||!user) throw new Error('Not signed in or invalid admin token.');
  const {data:staff}=await service.from('staff').select('role').eq('user_id',user.id).maybeSingle();
  if(staff?.role!=='admin') throw new Error('Admin role required');
  const body=await req.json(); const users=Array.isArray(body.users)?body.users:[];
  if(!users.length||users.length>100) throw new Error('Send 1 to 100 users');
  const results=[];
  for(const x of users){
   try{
    if(!x.email||!x.password||String(x.password).length<8) throw new Error('email and password of 8+ characters required');
    const {data, error}=await service.auth.admin.createUser({email:String(x.email).trim().toLowerCase(),password:String(x.password),email_confirm:true});
    if(error) throw error;
    const role=x.role==='admin'?'admin':'operator';
    const {error:se}=await service.from('staff').upsert({user_id:data.user.id,role},{onConflict:'user_id'});
    if(se) throw se;
    results.push({email:x.email,ok:true,role});
   }catch(e){results.push({email:x.email,ok:false,error:e.message||String(e)})}
  }
  return new Response(JSON.stringify({message:`Processed ${results.length} user(s)`,results}),{headers:{...cors,'Content-Type':'application/json'}});
 }catch(e){return new Response(JSON.stringify({error:e.message||String(e)}),{status:400,headers:{...cors,'Content-Type':'application/json'}})}
});