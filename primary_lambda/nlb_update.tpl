import dns.resolver
import boto3

def main(event, context):
    # Find and print A records
    result = dns.resolver.resolve('${vault_url}', 'A')
    dig_lst = []
    for val in result:
      dig_lst.append(val.to_text())

    print(f"The Vault DNS Endpoints are: {sorted(dig_lst)}")
    
    # NLB
    nlb = boto3.client('elbv2')
    
    # Get Target
    nlb_lst = []
    targets = nlb.describe_target_health(TargetGroupArn='${tg_arn}')
    
    for target in targets['TargetHealthDescriptions']:
      tgs = (target['Target']['Id'])
      nlb_lst.append(tgs)
    
    print(f"The Target Group Endpoints are: {sorted(nlb_lst)}")
    
    if set(dig_lst) == set(nlb_lst):
      print('Vault IP Endpoints are up to date')
    else:
      for u_tg in set(nlb_lst):
        nlb.deregister_targets(TargetGroupArn='${tg_arn}', Targets=[{'Id': u_tg}])
      for r_tg in set(dig_lst):
        nlb.register_targets(TargetGroupArn='${tg_arn}', Targets=[{'Id': r_tg, 'AvailabilityZone': 'all'}])
      print('Vault IP Endpoints have been updated')
